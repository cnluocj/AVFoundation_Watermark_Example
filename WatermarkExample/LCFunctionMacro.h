
#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height

#define RGBA(r, g, b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define RGB(r, g, b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]

#define LOCAL_VIDEO_FILE @"Documents/video123.mov"
#define LOCAL_VIDEO_PATH [NSHomeDirectory() stringByAppendingPathComponent:LOCAL_VIDEO_FILE];