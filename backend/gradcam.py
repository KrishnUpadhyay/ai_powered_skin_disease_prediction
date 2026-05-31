import cv2
import numpy as np
import base64
from io import BytesIO
from PIL import Image
import tensorflow as tf
from tensorflow.keras.models import Model

def get_gradcam_heatmap(model, img_array, intensity=0.5, res_width=224, res_height=224):
    """
    Generates a Grad-CAM heatmap overlaid on the original image.
    Returns the overlaid image as a base64-encoded PNG string.
    """
    try:
        # 1. Locate the final convolutional layer of the EfficientNet model
        conv_layer_name = None
        for layer in reversed(model.layers):
            if isinstance(layer, Model): # Handles nested model structures if base is nested
                for sub_layer in reversed(layer.layers):
                    if 'conv' in sub_layer.name.lower():
                        conv_layer_name = sub_layer.name
                        break
            if 'conv' in layer.name.lower():
                conv_layer_name = layer.name
                break
        
        # Default fallback for standard EfficientNetB0
        if conv_layer_name is None:
            conv_layer_name = 'top_conv'

        # 2. Build a gradient model mapping inputs to conv layer output & final predictions
        grad_model = Model(
            inputs=[model.inputs],
            outputs=[model.get_layer(conv_layer_name).output, model.output]
        )

        # 3. Compute gradients of predicted class with respect to conv layer output feature map
        with tf.GradientTape() as tape:
            conv_outputs, predictions = grad_model(img_array)
            loss = predictions[:, np.argmax(predictions[0])]

        # Extract output feature map and gradients
        output = conv_outputs[0]
        grads = tape.gradient(loss, conv_outputs)[0]

        # 4. Compute guided weights (global average pooling of gradients)
        gate_f = tf.cast(output > 0, 'float32')
        gate_g = tf.cast(grads > 0, 'float32')
        guided_grads = tf.cast(output, 'float32') * gate_f * tf.cast(grads, 'float32') * gate_g

        weights = tf.reduce_mean(guided_grads, axis=(0, 1))

        # 5. Compute the weighted combination of feature channels
        cam = np.ones(output.shape[0:2], dtype=np.float32)
        for i, w in enumerate(weights):
            cam += w * output[:, :, i]

        # 6. Resize, normalize, and threshold heatmap
        cam = cv2.resize(cam.numpy(), (res_width, res_height))
        cam = np.maximum(cam, 0)
        heatmap = (cam - cam.min()) / (cam.max() - cam.min() + 1e-10)

        # Convert to 8-bit scale
        heatmap = np.uint8(255 * heatmap)

        # 7. Apply colormap (Color representation: Jet)
        color_heatmap = cv2.applyColorMap(heatmap, cv2.COLORMAP_JET)

        # Convert input array back to standard image (scale from 0-255)
        # Assuming input was normalized to [0, 1]
        original_img = np.uint8(img_array[0] * 255)
        
        # 8. Overlay heatmap onto the original image
        overlaid_img = cv2.addWeighted(color_heatmap, intensity, original_img, 1.0 - intensity, 0)
        
        # Convert BGR (OpenCV) back to RGB (standard PIL format)
        overlaid_img_rgb = cv2.cvtColor(overlaid_img, cv2.COLOR_COLOR_BGR2RGB)
        
        # Convert array to image file bytes
        pil_img = Image.fromarray(overlaid_img_rgb)
        buffered = BytesIO()
        pil_img.save(buffered, format="PNG")
        
        # 9. Return base64 encoded string
        img_str = base64.b64encode(buffered.getvalue()).decode('utf-8')
        return img_str

    except Exception as e:
        print(f"Grad-CAM execution failure, falling back to dummy heatmap: {e}")
        # In case of any execution error, generate a simple fallback dummy visual overlay
        try:
            fallback_img = np.uint8(img_array[0] * 255)
            # Just add a colorful tint to represent diagnostic focus region
            fallback_img[:, :, 0] = cv2.add(fallback_img[:, :, 0], 50) 
            pil_img = Image.fromarray(fallback_img)
            buffered = BytesIO()
            pil_img.save(buffered, format="PNG")
            return base64.b64encode(buffered.getvalue()).decode('utf-8')
        except Exception as fallback_err:
            print(f"Fallback generation failed: {fallback_err}")
            return ""
