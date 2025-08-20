"""
中文字体配置模块
用于解决matplotlib中文显示问题
"""

import matplotlib.pyplot as plt
import matplotlib.font_manager as fm
import platform
import os


def setup_chinese_fonts():
    """设置中文字体支持"""
    
    # 获取系统中所有可用的字体
    available_fonts = [f.name for f in fm.fontManager.ttflist]
    
    # 定义中文字体优先级列表
    priority_fonts = [
        'SimHei',           # 黑体，支持中文
        'Microsoft YaHei', # 微软雅黑
        'SimSun',           # 宋体
        'KaiTi',            # 楷体
        'FangSong',         # 仿宋
        'Arial Unicode MS', # Unicode字体
        'Noto Sans CJK SC', # Noto中文
        'WenQuanYi Zen Hei' # 文泉驿正黑
    ]
    
    # 查找第一个可用的中文字体
    selected_font = None
    for font in priority_fonts:
        if font in available_fonts:
            selected_font = font
            break
    
    # 如果找到可用字体，设置matplotlib
    if selected_font:
        plt.rcParams['font.sans-serif'] = [selected_font] + [f for f in plt.rcParams['font.sans-serif'] if f != selected_font]
        plt.rcParams['axes.unicode_minus'] = False
        print(f"已设置中文字体: {selected_font}")
        return True
    else:
        # 使用系统默认字体，但添加备用方案
        plt.rcParams['font.sans-serif'] = ['DejaVu Sans', 'Arial', 'Helvetica']
        plt.rcParams['axes.unicode_minus'] = False
        print("警告：未找到合适的中文字体，使用默认字体，中文可能显示为方块")
        return False


def get_chinese_font():
    """获取中文字体名称"""
    system = platform.system()
    
    font_map = {
        "Darwin": ["PingFang SC", "Heiti SC", "Arial Unicode MS"],
        "Windows": ["SimHei", "Microsoft YaHei", "SimSun"],
        "Linux": ["WenQuanYi Zen Hei", "Noto Sans CJK SC", "SimHei"]
    }
    
    fonts = font_map.get(system, font_map["Linux"])
    
    # 检查字体是否可用
    for font in fonts:
        if font in [f.name for f in fm.fontManager.ttflist]:
            return font
    
    return None


def install_font_if_needed():
    """如果需要，安装中文字体"""
    try:
        # 检查是否已有中文字体
        chinese_fonts = [f for f in fm.fontManager.ttflist 
                        if any(name in f.name for name in ['SimHei', 'SimSun', 'PingFang', 'Heiti'])]
        
        if not chinese_fonts:
            print("建议安装中文字体以改善显示效果")
            print("macOS用户: 系统通常已内置PingFang SC")
            print("Windows用户: 系统通常已内置SimHei")
            print("Linux用户: 可安装fonts-noto-cjk或fonts-wqy-zenhei")
        
        return len(chinese_fonts) > 0
        
    except Exception as e:
        print(f"检查字体时出错: {e}")
        return False


def setup_matplotlib_for_chinese():
    """完整的中文字体设置"""
    success = setup_chinese_fonts()
    install_font_if_needed()
    
    # 设置其他matplotlib参数
    plt.rcParams['axes.titlesize'] = 14
    plt.rcParams['axes.labelsize'] = 12
    plt.rcParams['xtick.labelsize'] = 10
    plt.rcParams['ytick.labelsize'] = 10
    plt.rcParams['legend.fontsize'] = 10
    
    return success