# DermaScan AI: Unified Multi-Dataset Skin Disease Classification Pipeline

DermaScan AI features a state-of-the-art ensembled deep learning pipeline to identify skin conditions across 10 master classes consolidated from 4 major clinical datasets. It utilizes custom data augmentations (Mixup, Cutout, HSV Jitter, Gaussian Noise) to combat extreme dataset imbalances, and includes an API with Grad-CAM++ visualization overlays.

---

## 🔬 Unified 10-Class Master System
To maximize clinical classification utility across multiple dataset domains, the following unified classes are supported:
- **Class 0 (Melanoma):** Malignant melanoma skin cancers.
- **Class 1 (Melanocytic Nevi):** Common benign moles.
- **Class 2 (Basal Cell Carcinoma):** Basal Cell Carcinoma and Squamous Cell Carcinoma (Non-Melanoma Skin Cancer).
- **Class 3 (Actinic Keratosis):** Actinic Keratosis precancerous lesions.
- **Class 4 (Benign Keratosis):** Seborrheic keratosis and benign keratosis-like lesions.
- **Class 5 (Dermatofibroma):** Benign skin nodules.
- **Class 6 (Vascular Lesions):** Angiomas, pyogenic granulomas, hemorrhage, and vascular malformations.
- **Class 7 (Eczema / Dermatitis):** Inflammatory atopic and contact dermatitis.
- **Class 8 (Psoriasis):** Plaque psoriasis and related conditions.
- **Class 9 (Tinea / Fungal Infection):** Ringworm and other fungal skin infections.

---

## 🛠️ Codebase Structure

- `dataset_builder.py`: Integrates HAM10000, ISIC 2019, DermNet, and ISIC 2018 datasets. Implements stratified splitting and minority oversampling. Automatically generates mock data if local folders are empty.
- `augmentation.py`: A Keras-compatible sequence generator (`CombinedDataGenerator`) applying random flips, rotations, shifts, zooms, HSV color jitter, cutout, and mixup.
- `model_builder.py`: Defines the EfficientNetB3 and MobileNetV3Large ensemble architectures, along with the ensembled prediction module.
- `train_model.py`: Runs a 2-phase training regimen (head training followed by fine-tuning with cosine annealing schedule) for both models.
- `evaluate_model.py`: Generates the confusion matrix, F1-scores, recall metrics, and prints `evaluation_report.txt`.
- `gradcam.py`: Computes Grad-CAM++ activation maps targeting EfficientNetB3's top convolutional layers to overlay on predictions.
- `app.py`: Serves inference endpoints (`/predict`) and log storage (`/save-diary`, `/diary`) via Flask.

---

## 🚀 How to Run the Pipeline

### 1. Install Dependencies
Make sure you are inside the `backend/` directory:
```bash
pip install -r requirements.txt
```

### 2. Consolidate and Split Datasets
Run the dataset builder. If you do not have the raw datasets downloaded, the script will automatically generate a mock version:
```bash
python dataset_builder.py
```
This generates `data/train.csv`, `data/val.csv`, and `data/test.csv`.

### 3. Run Training (Quick Integration Test)
To verify the training script compiles and executes without running the full dataset:
```bash
python train_model.py --quick
```
To run full training:
```bash
python train_model.py
```
This saves checkpoint models `models/efficientnet_b3.h5` and `models/mobilenet_v3.h5`.

### 4. Evaluate Ensemble Models
Assess predictions, calculate per-class metrics, and generate the confusion matrix:
```bash
python evaluate_model.py
```
This outputs:
- `models/evaluation_report.txt`
- `models/confusion_matrix.png`

### 5. Run the Server
Launch the Flask backend server:
```bash
python app.py
```
The server binds to `0.0.0.0:5000` to allow external device and emulator connections.

---

## 🔮 Simulated Mode Fallback
If scientific libraries (`tensorflow`, `opencv-python`, etc.) are not installed globally, the codebase executes in simulated diagnostics mode:
- The dataset builder writes standard BMP bytes directly.
- The Flask backend runs deterministic image-hashing to mock predictions.
- Grad-CAM++ overlays yield mock tinted outputs.
This allows end-to-end frontend and database testing with zero compilation failures.
