import os
import random
import csv
import math

# 10 Master Classes
MASTER_CLASSES = {
    0: "Melanoma",
    1: "Melanocytic Nevi (Moles)",
    2: "Basal Cell Carcinoma",
    3: "Actinic Keratosis",
    4: "Benign Keratosis",
    5: "Dermatofibroma",
    6: "Vascular Lesions",
    7: "Eczema / Dermatitis",
    8: "Psoriasis",
    9: "Tinea / Fungal Infection"
}

def generate_mock_image(path):
    """Generates a tiny 2x2 BMP image to ensure code works out of the box without PIL."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if not os.path.exists(path):
        # 2x2 BMP file header and pixel values (red/blue)
        bmp_data = (
            b'BM' + 
            b'\x3e\x00\x00\x00' + # File size (62 bytes)
            b'\x00\x00\x00\x00' + # Reserved
            b'\x36\x00\x00\x00' + # Offset to pixel data
            b'\x28\x00\x00\x00' + # Header size
            b'\x02\x00\x00\x00' + # Width 2
            b'\x02\x00\x00\x00' + # Height 2
            b'\x01\x00' +         # Planes 1
            b'\x18\x00' +         # 24 bits per pixel (RGB)
            b'\x00\x00\x00\x00' + # Compression
            b'\x08\x00\x00\x00' + # Image size (8 bytes with padding)
            b'\x12\x0b\x00\x00' + # X pixels per meter
            b'\x12\x0b\x00\x00' + # Y pixels per meter
            b'\x00\x00\x00\x00' + # Colors in map
            b'\x00\x00\x00\x00' + # Important colors
            # Pixel data (BGR format, padded to 4 bytes per row)
            b'\x00\x00\xff\x00\x00\xff\x00\x00' + # Row 1 (Red pixels)
            b'\xff\x00\x00\xff\x00\x00\x00\x00'   # Row 2 (Blue pixels)
        )
        with open(path, 'wb') as f:
            f.write(bmp_data)

def build_mock_datasets(base_dir):
    """Automatically constructs a mock folder structure if the real data is not downloaded yet."""
    print("Real datasets not found on disk. Generating mock clinical datasets for testing...")
    
    # HAM10000 Mock
    ham_dir = os.path.join(base_dir, "ham10000")
    os.makedirs(os.path.join(ham_dir, "part1"), exist_ok=True)
    os.makedirs(os.path.join(ham_dir, "part2"), exist_ok=True)
    
    ham_records = []
    classes_ham = ["MEL", "NV", "BCC", "AKIEC", "BKL", "DF", "VASC"]
    for i in range(700):
        img_id = f"ISIC_0024{i:03d}"
        part = "part1" if i < 350 else "part2"
        # Using .bmp extension for our mock files
        path = os.path.join(ham_dir, part, f"{img_id}.bmp")
        generate_mock_image(path)
        ham_records.append({
            "image_id": img_id,
            "dx": classes_ham[i % 7],
            "age": random.randint(20, 80),
            "sex": random.choice(["male", "female"]),
            "localization": "back"
        })
    
    with open(os.path.join(ham_dir, "HAM10000_metadata.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["image_id", "dx", "age", "sex", "localization"])
        writer.writeheader()
        writer.writerows(ham_records)

    # ISIC 2019 Mock
    isic19_dir = os.path.join(base_dir, "isic2019")
    os.makedirs(os.path.join(isic19_dir, "ISIC_2019_Training_Input"), exist_ok=True)
    isic19_records = []
    classes_isic19 = ["MEL", "NV", "BCC", "AK", "BKL", "DF", "VASC", "SCC", "UNK"]
    for i in range(900):
        img_id = f"ISIC_0030{i:03d}"
        path = os.path.join(isic19_dir, "ISIC_2019_Training_Input", f"{img_id}.bmp")
        generate_mock_image(path)
        record = {"image": img_id}
        for c in classes_isic19:
            record[c] = 1.0 if c == classes_isic19[i % 9] else 0.0
        isic19_records.append(record)
        
    with open(os.path.join(isic19_dir, "ISIC_2019_Training_GroundTruth.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["image"] + classes_isic19)
        writer.writeheader()
        writer.writerows(isic19_records)

    # DermNet NZ Mock
    dermnet_dir = os.path.join(base_dir, "dermnet")
    folders_dermnet = [
        "Atopic Dermatitis Photos",
        "Psoriasis pictures Lichen Planus and related diseases",
        "Tinea Ringworm and Fungal Infections",
        "Actinic Keratosis Basal Cell Carcinoma and Squamous Cell Carcinoma Photos",
        "Melanoma Skin Cancer Nevi and Moles"
    ]
    for folder in folders_dermnet:
        f_path = os.path.join(dermnet_dir, folder)
        os.makedirs(f_path, exist_ok=True)
        for i in range(100):
            img_id = f"dermnet_{folder.replace(' ', '_').lower()}_{i}.bmp"
            generate_mock_image(os.path.join(f_path, img_id))

    # ISIC 2018 Mock
    isic18_dir = os.path.join(base_dir, "isic2018")
    os.makedirs(os.path.join(isic18_dir, "ISIC2018_Training_Input"), exist_ok=True)
    isic18_records = []
    for i in range(500):
        img_id = f"ISIC_0010{i:03d}"
        path = os.path.join(isic18_dir, "ISIC2018_Training_Input", f"{img_id}.bmp")
        generate_mock_image(path)
        record = {"image": img_id}
        for c in ["MEL", "NV", "BCC", "AKIEC", "BKL", "DF", "VASC"]:
            record[c] = 1.0 if c == ["MEL", "NV", "BCC", "AKIEC", "BKL", "DF", "VASC"][i % 7] else 0.0
        isic18_records.append(record)
        
    with open(os.path.join(isic18_dir, "ISIC2018_Training_GroundTruth.csv"), "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["image", "MEL", "NV", "BCC", "AKIEC", "BKL", "DF", "VASC"])
        writer.writeheader()
        writer.writerows(isic18_records)
    print("Mock datasets built successfully.")

def build_dataset(base_dir="data"):
    # Trigger mock generator if paths are missing
    if not (os.path.exists(os.path.join(base_dir, "ham10000")) and 
            os.path.exists(os.path.join(base_dir, "isic2019"))):
        build_mock_datasets(base_dir)

    all_data = []

    # Helper to scan directory for images
    def find_images(dir_path, filename_prefix):
        found = []
        for ext in [".jpg", ".jpeg", ".png", ".bmp"]:
            cand = os.path.join(dir_path, f"{filename_prefix}{ext}")
            if os.path.exists(cand):
                found.append(cand)
        return found[0] if found else ""

    # 1. DATASET 1: HAM10000
    ham_dir = os.path.join(base_dir, "ham10000")
    ham_csv = os.path.join(ham_dir, "HAM10000_metadata.csv")
    if os.path.exists(ham_csv):
        with open(ham_csv, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            ham_map = {
                "MEL": 0, "NV": 1, "BCC": 2, "AKIEC": 3,
                "BKL": 4, "DF": 5, "VASC": 6
            }
            for row in reader:
                img_id = row['image_id']
                img_path = ""
                for p in ["part1", "part2"]:
                    img_path = find_images(os.path.join(ham_dir, p), img_id)
                    if img_path:
                        break
                
                dx = row['dx']
                if img_path and dx in ham_map:
                    all_data.append({
                        "image_path": img_path,
                        "label_id": ham_map[dx],
                        "label_name": MASTER_CLASSES[ham_map[dx]],
                        "source_dataset": "HAM10000"
                    })

    # 2. DATASET 2: ISIC 2019
    isic19_dir = os.path.join(base_dir, "isic2019")
    isic19_csv = os.path.join(isic19_dir, "ISIC_2019_Training_GroundTruth.csv")
    if os.path.exists(isic19_csv):
        with open(isic19_csv, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                img_id = row['image']
                img_path = find_images(os.path.join(isic19_dir, "ISIC_2019_Training_Input"), img_id)
                if img_path:
                    lbl_id = None
                    if row.get('MEL') == '1.0': lbl_id = 0
                    elif row.get('NV') == '1.0': lbl_id = 1
                    elif row.get('BCC') == '1.0': lbl_id = 2
                    elif row.get('AK') == '1.0': lbl_id = 3
                    elif row.get('BKL') == '1.0': lbl_id = 4
                    elif row.get('DF') == '1.0': lbl_id = 5
                    elif row.get('VASC') == '1.0': lbl_id = 6
                    elif row.get('SCC') == '1.0': lbl_id = 2 # SCC maps to BCC
                    
                    if lbl_id is not None:
                        all_data.append({
                            "image_path": img_path,
                            "label_id": lbl_id,
                            "label_name": MASTER_CLASSES[lbl_id],
                            "source_dataset": "ISIC 2019"
                        })

    # 3. DATASET 3: DermNet NZ
    dermnet_dir = os.path.join(base_dir, "dermnet")
    if os.path.exists(dermnet_dir):
        for root, dirs, files in os.walk(dermnet_dir):
            for file in files:
                if file.lower().endswith(('.jpg', '.jpeg', '.png', '.bmp')):
                    full_path = os.path.join(root, file)
                    rel_dir = os.path.basename(root).lower()
                    lbl_id = None
                    
                    if "atopic" in rel_dir or "eczema" in rel_dir:
                        lbl_id = 7
                    elif "psoriasis" in rel_dir:
                        lbl_id = 8
                    elif "tinea" in rel_dir or "fungal" in rel_dir or "ringworm" in rel_dir:
                        lbl_id = 9
                    elif "melanoma" in rel_dir:
                        if "melanoma" in file.lower(): lbl_id = 0
                        elif "nevi" in file.lower() or "mole" in file.lower(): lbl_id = 1
                        elif "seborrheic" in file.lower(): lbl_id = 4
                    elif "actinic" in rel_dir or "basal" in rel_dir:
                        if "actinic" in file.lower(): lbl_id = 3
                        elif "basal" in file.lower() or "squamous" in file.lower(): lbl_id = 2
                    elif "dermatofibroma" in rel_dir:
                        lbl_id = 5
                    elif "vascular" in rel_dir:
                        lbl_id = 6

                    if lbl_id is not None:
                        all_data.append({
                            "image_path": full_path,
                            "label_id": lbl_id,
                            "label_name": MASTER_CLASSES[lbl_id],
                            "source_dataset": "DermNet"
                        })

    # 4. DATASET 4: ISIC 2018
    isic18_dir = os.path.join(base_dir, "isic2018")
    isic18_csv = os.path.join(isic18_dir, "ISIC2018_Training_GroundTruth.csv")
    if os.path.exists(isic18_csv):
        with open(isic18_csv, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                img_id = row['image']
                img_path = find_images(os.path.join(isic18_dir, "ISIC2018_Training_Input"), img_id)
                if img_path:
                    lbl_id = None
                    if row.get('MEL') == '1.0': lbl_id = 0
                    elif row.get('NV') == '1.0': lbl_id = 1
                    elif row.get('BCC') == '1.0': lbl_id = 2
                    elif row.get('AKIEC') == '1.0': lbl_id = 3
                    elif row.get('BKL') == '1.0': lbl_id = 4
                    elif row.get('DF') == '1.0': lbl_id = 5
                    elif row.get('VASC') == '1.0': lbl_id = 6

                    if lbl_id is not None:
                        all_data.append({
                            "image_path": img_path,
                            "label_id": lbl_id,
                            "label_name": MASTER_CLASSES[lbl_id],
                            "source_dataset": "ISIC 2018"
                        })

    print(f"\nConsolidated Merged Dataset: {len(all_data)} total images loaded.")
    
    # Handle Class Imbalance via Oversampling Minority Classes (target min 2,000 samples per class)
    print("\nHandling Class Imbalance...")
    balanced_data = []
    
    # Group entries by label_id
    by_class = {}
    for entry in all_data:
        lbl = entry['label_id']
        if lbl not in by_class:
            by_class[lbl] = []
        by_class[lbl].append(entry)

    for class_id, class_name in MASTER_CLASSES.items():
        class_subset = by_class.get(class_id, [])
        count = len(class_subset)
        print(f"Class {class_id} ({class_name}): {count} initial samples.")
        
        if count == 0:
            continue
            
        if count < 2000:
            # Oversample to meet 2,000 requirement
            multiplier = int(math.ceil(2000 / count))
            oversampled_subset = class_subset * multiplier
            # Shuffle and slice to 2000
            random.seed(42)
            random.shuffle(oversampled_subset)
            oversampled_subset = oversampled_subset[:2000]
            balanced_data.extend(oversampled_subset)
        else:
            balanced_data.extend(class_subset)

    print(f"Balanced Dataset count: {len(balanced_data)} total images.")

    # Stratified Split: 70% Train, 15% Val, 15% Test
    print("\nSplitting dataset (70/15/15 Stratified)...")
    
    # Group balanced by class
    class_groups = {}
    for entry in balanced_data:
        lbl = entry['label_id']
        if lbl not in class_groups:
            class_groups[lbl] = []
        class_groups[lbl].append(entry)
        
    train_list, val_list, test_list = [], [], []
    for class_id, group in class_groups.items():
        random.seed(42)
        random.shuffle(group)
        
        n_total = len(group)
        n_train = int(n_total * 0.70)
        n_val = int(n_total * 0.15)
        
        train_list.extend(group[:n_train])
        val_list.extend(group[n_train:n_train + n_val])
        test_list.extend(group[n_train + n_val:])

    # Save splits to data directory
    os.makedirs(base_dir, exist_ok=True)
    
    fieldnames = ["image_path", "label_id", "label_name", "source_dataset"]
    
    def save_split_csv(split_data, filename):
        with open(os.path.join(base_dir, filename), "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(split_data)

    save_split_csv(train_list, "train.csv")
    save_split_csv(val_list, "val.csv")
    save_split_csv(test_list, "test.csv")
    
    print("\nDataset preparation finished successfully!")
    print(f"Train split: {len(train_list)} samples")
    print(f"Val split: {len(val_list)} samples")
    print(f"Test split: {len(test_list)} samples")
    
    # Calculate training class weights
    total_balanced = len(train_list)
    class_weights = {}
    class_counts_train = {}
    for entry in train_list:
        lbl = entry['label_id']
        class_counts_train[lbl] = class_counts_train.get(lbl, 0) + 1
        
    for class_id in MASTER_CLASSES.keys():
        cnt = class_counts_train.get(class_id, 1)
        class_weights[class_id] = total_balanced / (len(MASTER_CLASSES) * cnt)
    
    print(f"\nCalculated training Class Weights: {class_weights}")
    
    # Save mapping dict to models
    os.makedirs("models", exist_ok=True)
    import json
    with open("models/class_labels.json", "w") as f:
        json.dump({str(k): v for k, v in MASTER_CLASSES.items()}, f, indent=2)

if __name__ == "__main__":
    build_dataset()
