import os
import json
import numpy as np
import tensorflow as tf
from tensorflow.keras.applications import EfficientNetB4
from tensorflow.keras.layers import GlobalAveragePooling2D, Dense, Dropout, BatchNormalization
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau

def build_model(num_classes=30):
    # Upgraded base pre-trained EfficientNetB4 model (scales resolution, depth, and width; ImageNet Top-1 Accuracy: 82.9%)
    base_model = EfficientNetB4(weights='imagenet', include_top=False, input_shape=(380, 380, 3))
    
    # Freeze the base model layers initially
    base_model.trainable = False
    
    # Add custom diagnostic head with dual BatchNormalization and L2 regularization to accelerate convergence and prevent overfitting
    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = BatchNormalization()(x)
    x = Dense(512, activation='relu', kernel_regularizer=tf.keras.regularizers.l2(0.005))(x)
    x = BatchNormalization()(x)
    x = Dropout(0.5)(x)
    predictions = Dense(num_classes, activation='softmax')(x)
    
    model = Model(inputs=base_model.input, outputs=predictions)
    return model, base_model

def train_skin_classifier(dataset_dir):
    print("Initializing upgraded ultra-accuracy EfficientNetB4 training pipeline...")
    
    # Setup data generators with strong clinical-lesion augmentations
    train_datagen = ImageDataGenerator(
        rescale=1./255,
        rotation_range=40,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        horizontal_flip=True,
        vertical_flip=True,
        fill_mode='nearest',
        validation_split=0.2
    )
    
    # Flow training and validation inputs (Scaled to B4 specific 380x380 resolution)
    train_generator = train_datagen.flow_from_directory(
        dataset_dir,
        target_size=(380, 380),
        batch_size=16, # EfficientNetB4 requires smaller batch sizes due to larger memory footprint
        class_mode='categorical',
        subset='training'
    )
    
    val_generator = train_datagen.flow_from_directory(
        dataset_dir,
        target_size=(380, 380),
        batch_size=16,
        class_mode='categorical',
        subset='validation'
    )
    
    # Build models
    num_classes = len(train_generator.class_indices)
    model, base_model = build_model(num_classes)
    
    # Save the class label mappings
    labels_mapping = {v: k for k, v in train_generator.class_indices.items()}
    os.makedirs('model', exist_ok=True)
    with open('model/class_labels.json', 'w') as f:
        json.dump(labels_mapping, f, indent=2)
        
    # Calculate dynamic class weights to combat extreme dataset imbalances
    class_counts = train_generator.classes
    total_samples = len(class_counts)
    class_frequencies = {}
    for c in class_counts:
        class_frequencies[c] = class_frequencies.get(c, 0) + 1
        
    class_weights = {}
    for k, v in class_frequencies.items():
        class_weights[k] = total_samples / (num_classes * v)
        
    print(f"Calculated Dynamic Class Weights across {num_classes} classes: {class_weights}")
    
    # Compile model with categorical crossentropy (or custom loss)
    model.compile(
        optimizer=Adam(learning_rate=1e-4),
        loss='categorical_crossentropy',
        metrics=['accuracy', tf.keras.metrics.AUC(name='auc')]
    )
    
    # Define optimization callbacks
    callbacks = [
        EarlyStopping(monitor='val_loss', patience=6, restore_best_weights=True, verbose=1),
        ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=3, min_lr=1e-6, verbose=1),
        ModelCheckpoint('model/skin_model.h5', monitor='val_loss', save_best_only=True, verbose=1)
    ]
    
    # Step 1: Train the classification head
    print("Phase 1: Training custom classification head...")
    model.fit(
        train_generator,
        epochs=12,
        validation_data=val_generator,
        class_weight=class_weights,
        callbacks=callbacks
    )
    
    # Step 2: Unfreeze last 20 layers for fine-tuning
    print("Phase 2: Unfreezing final 20 base layers for advanced fine-tuning...")
    base_model.trainable = True
    for layer in base_model.layers[:-20]:
        layer.trainable = False
        
    # Re-compile model with a lower learning rate to preserve weights
    model.compile(
        optimizer=Adam(learning_rate=1e-5),
        loss='categorical_crossentropy',
        metrics=['accuracy', tf.keras.metrics.AUC(name='auc')]
    )
    
    # Continue training/fine-tuning
    print("Starting advanced fine-tuning pipeline...")
    model.fit(
        train_generator,
        epochs=20,
        validation_data=val_generator,
        class_weight=class_weights,
        callbacks=callbacks
    )
    
    print(f"DermaScan AI training complete! Upgraded {num_classes}-class EfficientNetB4 checkpoint saved to model/skin_model.h5")

if __name__ == '__main__':
    dataset_path = './dataset'
    if os.path.exists(dataset_path):
        train_skin_classifier(dataset_path)
    else:
        print(f"Dataset path '{dataset_path}' not found. Place your HAM10000 images in the folder and run again.")
