import os
import csv
import random
import math
import hashlib
import numpy as np

try:
    import cv2
    import tensorflow as tf
    HAS_LIBS = True
except ImportError:
    HAS_LIBS = False
    cv2 = None
    tf = None

# If tensorflow is available, we inherit from tf.keras.utils.Sequence.
# Otherwise, we create a dummy sequence class so code compiles and can run in simulation mode.
if HAS_LIBS:
    SequenceBase = tf.keras.utils.Sequence
else:
    class SequenceBase:
        def __init__(self, *args, **kwargs):
            pass

class CombinedDataGenerator(SequenceBase):
    """
    A custom Keras Sequence generator that loads images from train/val/test CSV splits,
    applies standard augmentations (flips, shifts, rotation, zoom) and custom advanced
    augmentations (Cutout, Mixup, HSV Color Jitter, Gaussian Noise).
    """
    def __init__(self, csv_path, batch_size=32, target_size=(300, 300), shuffle=True, augment=False, num_classes=10, mixup_alpha=0.2):
        super().__init__()
        self.csv_path = csv_path
        self.batch_size = batch_size
        self.target_size = target_size
        self.shuffle = shuffle
        self.augment = augment
        self.num_classes = num_classes
        self.mixup_alpha = mixup_alpha
        
        self.data = []
        if os.path.exists(csv_path):
            with open(csv_path, 'r', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    self.data.append(row)
        else:
            print(f"Warning: CSV file {csv_path} not found.")
            
        self.indexes = np.arange(len(self.data))
        self.on_epoch_end()
        
    def __len__(self):
        if len(self.data) == 0:
            return 0
        return int(np.ceil(len(self.data) / self.batch_size))
        
    def on_epoch_end(self):
        if self.shuffle and len(self.data) > 0:
            np.random.shuffle(self.indexes)
            
    def __getitem__(self, idx):
        if len(self.data) == 0:
            # Return empty batch placeholder to prevent crashes
            return np.zeros((0, *self.target_size, 3), dtype=np.float32), np.zeros((0, self.num_classes), dtype=np.float32)
            
        # Determine indexes of the batch
        batch_indexes = self.indexes[idx * self.batch_size : (idx + 1) * self.batch_size]
        
        # In case the last batch is empty
        if len(batch_indexes) == 0:
            batch_indexes = self.indexes[:self.batch_size]
            
        batch_images = []
        batch_labels = []
        
        for index in batch_indexes:
            row = self.data[index]
            img_path = row['image_path']
            # Reconstruct path if needed relative to CSV location
            resolved_path = img_path
            if not os.path.exists(resolved_path):
                # Try relative to the CSV's directory
                csv_dir = os.path.dirname(os.path.abspath(self.csv_path))
                resolved_path = os.path.join(csv_dir, "..", img_path)
                if not os.path.exists(resolved_path):
                    # Check absolute / direct subpaths
                    resolved_path = os.path.join(csv_dir, os.path.basename(img_path))
                    if not os.path.exists(resolved_path):
                        resolved_path = img_path # fallback
            
            img = self._load_and_preprocess_image(resolved_path)
            label = int(row['label_id'])
            
            # One-hot label
            one_hot = np.zeros(self.num_classes, dtype=np.float32)
            if 0 <= label < self.num_classes:
                one_hot[label] = 1.0
                
            # Apply individual augmentations if required (excluding Mixup which is batch-wise)
            if self.augment:
                img = self._apply_individual_augmentations(img)
                
            batch_images.append(img)
            batch_labels.append(one_hot)
            
        batch_images = np.array(batch_images, dtype=np.float32)
        batch_labels = np.array(batch_labels, dtype=np.float32)
        
        # Apply Mixup on the batch if training
        if self.augment and self.mixup_alpha > 0 and len(batch_images) > 0:
            batch_images, batch_labels = self._apply_mixup(batch_images, batch_labels)
            
        return batch_images, batch_labels
        
    def _load_and_preprocess_image(self, path):
        # Load image using OpenCV or return fallback
        if HAS_LIBS and cv2 is not None:
            try:
                img = cv2.imread(path)
                if img is not None:
                    img = cv2.resize(img, self.target_size)
                    # Convert BGR to RGB
                    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
                    return img.astype(np.float32) / 255.0
            except Exception as e:
                pass
                
        # Fallback dummy image if cv2 fails or is missing or path doesn't exist
        # Generates a solid/patterned color block based on the path string hash
        h, w = self.target_size
        seed = int(hashlib.md5(path.encode()).hexdigest(), 16) % 256
        dummy = np.zeros((h, w, 3), dtype=np.float32)
        dummy[:, :, 0] = (seed % 256) / 255.0
        dummy[:, :, 1] = ((seed * 2) % 256) / 255.0
        dummy[:, :, 2] = ((seed * 3) % 256) / 255.0
        return dummy

    def _apply_individual_augmentations(self, image):
        if not HAS_LIBS or cv2 is None:
            # Simple flips in pure python / numpy
            if np.random.rand() > 0.5:
                image = np.fliplr(image)
            if np.random.rand() > 0.5:
                image = np.flipud(image)
            return image
            
        h, w = image.shape[:2]
        
        # 1. Random Flips
        if np.random.rand() > 0.5:
            image = cv2.flip(image, 1) # horizontal
        if np.random.rand() > 0.5:
            image = cv2.flip(image, 0) # vertical
            
        # 2. Random Rotation (-40 to 40 degrees)
        if np.random.rand() > 0.5:
            angle = np.random.uniform(-40, 40)
            M = cv2.getRotationMatrix2D((w / 2, h / 2), angle, 1.0)
            image = cv2.warpAffine(image, M, (w, h), borderMode=cv2.BORDER_REFLECT)
            
        # 3. Random Translation / Shift (up to 20%)
        if np.random.rand() > 0.5:
            tx = np.random.uniform(-0.2, 0.2) * w
            ty = np.random.uniform(-0.2, 0.2) * h
            M = np.float32([[1, 0, tx], [0, 1, ty]])
            image = cv2.warpAffine(image, M, (w, h), borderMode=cv2.BORDER_REFLECT)
            
        # 4. Random Zoom (80% to 120%)
        if np.random.rand() > 0.5:
            zoom_factor = np.random.uniform(0.8, 1.2)
            nh, nw = int(h * zoom_factor), int(w * zoom_factor)
            if zoom_factor < 1.0:
                # Zoom in: Crop from center and resize up
                cy, cx = h // 2, w // 2
                cropped = image[max(0, cy - nh // 2) : min(h, cy + nh // 2), 
                                max(0, cx - nw // 2) : min(w, cx + nw // 2)]
                image = cv2.resize(cropped, (w, h))
            else:
                # Zoom out: Resize down, then reflect pad or crop center
                resized = cv2.resize(image, (nw, nh))
                cy, cx = nh // 2, nw // 2
                image = resized[cy - h // 2 : cy + h // 2, cx - w // 2 : cx + w // 2]
                
        # 5. HSV Color Jitter
        if np.random.rand() > 0.5:
            try:
                # OpenCV works with RGB (our format) -> HSV
                hsv = cv2.cvtColor((image * 255.0).astype(np.uint8), cv2.COLOR_RGB2HSV).astype(np.float32)
                hv, sv, vv = cv2.split(hsv)
                
                # Hue shift
                h_shift = np.random.uniform(-15, 15)
                hv = np.mod(hv + h_shift, 180)
                
                # Saturation jitter
                s_scale = np.random.uniform(0.7, 1.3)
                sv = np.clip(sv * s_scale, 0, 255)
                
                # Value (brightness) jitter
                v_scale = np.random.uniform(0.7, 1.3)
                vv = np.clip(vv * v_scale, 0, 255)
                
                hsv_merged = cv2.merge([hv, sv, vv]).astype(np.uint8)
                image = cv2.cvtColor(hsv_merged, cv2.COLOR_HSV2RGB).astype(np.float32) / 255.0
            except Exception as e:
                pass
                
        # 6. Cutout (Random black block masking)
        if np.random.rand() > 0.4:
            mask_size = int(min(h, w) * 0.15)
            y = np.random.randint(0, h)
            x = np.random.randint(0, w)
            y1 = np.clip(y - mask_size // 2, 0, h)
            y2 = np.clip(y + mask_size // 2, 0, h)
            x1 = np.clip(x - mask_size // 2, 0, w)
            x2 = np.clip(x + mask_size // 2, 0, w)
            image = image.copy()
            image[y1:y2, x1:x2, :] = 0.0
            
        # 7. Gaussian Noise Injection
        if np.random.rand() > 0.4:
            noise = np.random.normal(0, 0.02, image.shape)
            image = np.clip(image + noise, 0.0, 1.0)
            
        return image
        
    def _apply_mixup(self, images, labels):
        batch_size = len(images)
        indices = np.random.permutation(batch_size)
        
        mixed_images = []
        mixed_labels = []
        
        for i in range(batch_size):
            j = indices[i]
            # Beta distribution with alpha = 0.2
            lam = np.random.beta(self.mixup_alpha, self.mixup_alpha) if self.mixup_alpha > 0 else 1.0
            
            img_i = images[i]
            img_j = images[j]
            lbl_i = labels[i]
            lbl_j = labels[j]
            
            mixed_img = lam * img_i + (1.0 - lam) * img_j
            mixed_lbl = lam * lbl_i + (1.0 - lam) * lbl_j
            
            mixed_images.append(mixed_img)
            mixed_labels.append(mixed_lbl)
            
        return np.array(mixed_images, dtype=np.float32), np.array(mixed_labels, dtype=np.float32)
