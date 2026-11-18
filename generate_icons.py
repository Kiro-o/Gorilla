import os
from PIL import Image

def main():
    src_path = 'icon.png'
    if not os.path.exists(src_path):
        print('Error: icon.png does not exist!')
        return

    src_img = Image.open(src_path).convert('RGBA')
    bg_color_rgba = (10, 13, 18, 255)  # Dark cyber gym #0A0D12
    bg_color_rgb = (10, 13, 18)        # Opaque for iOS

    # ─── 1. Web PWA Icons ────────────────────────────────────────────
    web_dir = 'web'
    web_icons_dir = os.path.join(web_dir, 'icons')
    os.makedirs(web_icons_dir, exist_ok=True)

    # Standard PWA icons
    # pwa-192x192.png
    src_img.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_dir, 'pwa-192x192.png'))
    print('Generated web/pwa-192x192.png')

    # pwa-512x192.png (512x192 wide banner/icon specified by user)
    pwa_wide = Image.new('RGBA', (512, 192), bg_color_rgba)
    h_icon = src_img.resize((180, 180), Image.Resampling.LANCZOS)
    pwa_wide.paste(h_icon, ((512 - 180) // 2, (192 - 180) // 2), h_icon)
    pwa_wide.save(os.path.join(web_dir, 'pwa-512x192.png'))
    print('Generated web/pwa-512x192.png')

    # pwa-512x512.png
    src_img.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_dir, 'pwa-512x512.png'))
    print('Generated web/pwa-512x512.png')

    # apple-touch-icon.png (180x180 solid background RGB for Safari / iOS home screen)
    ati = Image.new('RGB', (180, 180), bg_color_rgb)
    inner_ati = src_img.resize((164, 164), Image.Resampling.LANCZOS)
    ati.paste(inner_ati, (8, 8), inner_ati)
    ati.save(os.path.join(web_dir, 'apple-touch-icon.png'), 'PNG')
    ati.save(os.path.join(web_dir, 'apple-touch-icon-180x180.png'), 'PNG')
    print('Generated web/apple-touch-icon.png')

    # favicon.png (48x48)
    src_img.resize((48, 48), Image.Resampling.LANCZOS).save(os.path.join(web_dir, 'favicon.png'))
    print('Generated web/favicon.png')

    # web/icon.png (512x512)
    src_img.save(os.path.join(web_dir, 'icon.png'))
    print('Generated web/icon.png')

    # web/icons/Icon-192.png & Icon-512.png
    src_img.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, 'Icon-192.png'))
    src_img.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, 'Icon-512.png'))
    print('Generated web/icons/Icon-192.png & Icon-512.png')

    # Maskable icons (Icon inside 80% safe zone with solid background)
    for sz in [192, 512]:
        maskable = Image.new('RGBA', (sz, sz), bg_color_rgba)
        inner_sz = int(sz * 0.8)
        inner_icon = src_img.resize((inner_sz, inner_sz), Image.Resampling.LANCZOS)
        offset = (sz - inner_sz) // 2
        maskable.paste(inner_icon, (offset, offset), inner_icon)
        maskable.save(os.path.join(web_icons_dir, f'Icon-maskable-{sz}.png'))
    print('Generated maskable PWA icons')

    # ─── 2. Android mipmap icons ─────────────────────────────────────
    android_res = os.path.join('android', 'app', 'src', 'main', 'res')
    android_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    for folder, size in android_sizes.items():
        target_dir = os.path.join(android_res, folder)
        os.makedirs(target_dir, exist_ok=True)
        resized = src_img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(os.path.join(target_dir, 'ic_launcher.png'))
        resized.save(os.path.join(target_dir, 'ic_launcher_round.png'))
    print('Generated Android mipmap ic_launcher icons (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)')

    # ─── 3. iOS AppIcon set ──────────────────────────────────────────
    ios_dir = os.path.join('ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    os.makedirs(ios_dir, exist_ok=True)
    ios_files = {
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
        'Icon-App-1024x1024@1x.png': 1024,
    }
    for filename, size in ios_files.items():
        # iOS icons MUST be 100% opaque RGB (no alpha)
        canvas = Image.new('RGB', (size, size), bg_color_rgb)
        scaled_icon = src_img.resize((size, size), Image.Resampling.LANCZOS)
        canvas.paste(scaled_icon, (0, 0), scaled_icon)
        canvas.save(os.path.join(ios_dir, filename), 'PNG')
    print('Generated all iOS AppIcon set images (including 1024x1024 marketing icon)')

    # ─── 4. macOS icons ──────────────────────────────────────────────
    mac_dir = os.path.join('macos', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    if os.path.exists(mac_dir):
        mac_files = {
            'app_icon_16.png': 16,
            'app_icon_32.png': 32,
            'app_icon_64.png': 64,
            'app_icon_128.png': 128,
            'app_icon_256.png': 256,
            'app_icon_512.png': 512,
            'app_icon_1024.png': 1024,
        }
        for filename, size in mac_files.items():
            canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
            scaled_icon = src_img.resize((size, size), Image.Resampling.LANCZOS)
            canvas.paste(scaled_icon, (0, 0), scaled_icon)
            canvas.save(os.path.join(mac_dir, filename), 'PNG')
        print('Generated macOS AppIcon set images')

    # ─── 5. Windows app_icon.ico ─────────────────────────────────────
    win_dir = os.path.join('windows', 'runner', 'resources')
    if os.path.exists(win_dir):
        ico_sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
        src_img.save(os.path.join(win_dir, 'app_icon.ico'), format='ICO', sizes=ico_sizes)
        print('Generated Windows app_icon.ico')

    print('\nSUCCESS: All launcher icons generated across Android, iOS, Web, macOS, and Windows!')

if __name__ == '__main__':
    main()

