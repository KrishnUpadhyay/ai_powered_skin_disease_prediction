import os
import json
import numpy as np

try:
    import tensorflow as tf
    from tensorflow.keras.applications import EfficientNetB3, MobileNetV3Large
    from tensorflow.keras.layers import GlobalAveragePooling2D, Dense, Dropout, BatchNormalization, Input
    from tensorflow.keras.models import Model
    HAS_LIBS = True
except ImportError:
    HAS_LIBS = False
    tf = None

def build_efficientnet_b3(num_classes=10):
    """
    Builds the high-accuracy EfficientNetB3 model (input_shape=(300, 300, 3)).
    We freeze the base model by default, but let train_model.py handle fine-tuning layers.
    """
    if not HAS_LIBS:
        return None, None
        
    base_model = EfficientNetB3(weights='imagenet', include_top=False, input_shape=(300, 300, 3))
    base_model.trainable = False
    
    inputs = Input(shape=(300, 300, 3))
    x = base_model(inputs, training=False)
    x = GlobalAveragePooling2D()(x)
    x = BatchNormalization()(x)
    x = Dense(512, activation='relu', kernel_regularizer=tf.keras.regularizers.l2(0.005))(x)
    x = BatchNormalization()(x)
    x = Dropout(0.4)(x)
    x = Dense(256, activation='relu', kernel_regularizer=tf.keras.regularizers.l2(0.005))(x)
    x = BatchNormalization()(x)
    x = Dropout(0.3)(x)
    outputs = Dense(num_classes, activation='softmax')(x)
    
    model = Model(inputs=inputs, outputs=outputs, name="EfficientNetB3_Ensemble_A")
    return model, base_model

def build_mobilenet_v3(num_classes=10):
    """
    Builds the speed-focused MobileNetV3Large model (input_shape=(224, 224, 3)).
    """
    if not HAS_LIBS:
        return None, None
        
    base_model = MobileNetV3Large(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
    base_model.trainable = False
    
    inputs = Input(shape=(224, 224, 3))
    x = base_model(inputs, training=False)
    x = GlobalAveragePooling2D()(x)
    x = BatchNormalization()(x)
    x = Dense(256, activation='relu', kernel_regularizer=tf.keras.regularizers.l2(0.005))(x)
    x = BatchNormalization()(x)
    x = Dropout(0.3)(x)
    outputs = Dense(num_classes, activation='softmax')(x)
    
    model = Model(inputs=inputs, outputs=outputs, name="MobileNetV3Large_Ensemble_B")
    return model, base_model

class EnsemblePredictor:
    """
    A helper to load and run ensembled inference on loaded Model A and Model B.
    """
    def __init__(self, model_a_path=None, model_b_path=None):
        self.model_a = None
        self.model_b = None
        
        if HAS_LIBS:
            if model_a_path and os.path.exists(model_a_path):
                try:
                    self.model_a = tf.keras.models.load_model(model_a_path)
                    print(f"Successfully loaded EfficientNetB3 model from {model_a_path}")
                except Exception as e:
                    print(f"Error loading model A: {e}")
            if model_b_path and os.path.exists(model_b_path):
                try:
                    self.model_b = tf.keras.models.load_model(model_b_path)
                    print(f"Successfully loaded MobileNetV3 model from {model_b_path}")
                except Exception as e:
                    print(f"Error loading model B: {e}")
                
    def predict(self, image_np):
        """
        image_np is a numpy array of shape (H, W, 3) in range [0, 1].
        If both models are available:
          - Resize image to 300x300 for model_a.
          - Resize image to 224x224 for model_b.
          - Average the predictions.
        Otherwise use whichever is loaded or return a random prediction if running in simulated mode.
        """
        if not HAS_LIBS or (self.model_a is None and self.model_b is None):
            # Simulated mode prediction based on image hash for reproducibility
            import hashlib
            seed = int(hashlib.md5(str(image_np.shape).encode()).hexdigest(), 16) % 10
            preds = np.zeros(10)
            preds[seed] = 0.85
            preds[(seed + 1) % 10] = 0.10
            preds[(seed + 2) % 10] = 0.05
            return preds
            
        import cv2
        preds_a, preds_b = None, None
        
        # Ensure image has shape (H, W, 3)
        if len(image_np.shape) == 4:
            img = image_np[0]
        else:
            img = image_np
            
        if self.model_a is not None:
            try:
                img_a = cv2.resize(img, (300, 300))
                img_a = np.expand_dims(img_a, axis=0)
                preds_a = self.model_a.predict(img_a, verbose=0)[0]
            except Exception as e:
                print(f"Prediction failed on model A: {e}")
            
        if self.model_b is not None:
            try:
                img_b = cv2.resize(img, (224, 224))
                img_b = np.expand_dims(img_b, axis=0)
                preds_b = self.model_b.predict(img_b, verbose=0)[0]
            except Exception as e:
                print(f"Prediction failed on model B: {e}")
            
        if preds_a is not None and preds_b is not None:
            # Ensembled average
            return (preds_a + preds_b) / 2.0
        elif preds_a is not None:
            return preds_a
        elif preds_b is not None:
            return preds_b
        else:
            # Final fallback
            preds = np.zeros(10)
            preds[0] = 1.0
            return preds
