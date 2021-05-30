#import "SoundpoolPlugin.h"
#if __has_include(<soundpool/soundpool-Swift.h>)
#import <soundpool/soundpool-Swift.h>
#else
#import "soundpool-Swift.h"
#endif

@implementation SoundpoolPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSoundpoolPlugin registerWithRegistrar:registrar];
}
@end
