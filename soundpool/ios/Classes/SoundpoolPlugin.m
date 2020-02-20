#import "SoundpoolPlugin.h"
#import <soundpool/soundpool-Swift.h>

@implementation SoundpoolPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSoundpoolPlugin registerWithRegistrar:registrar];
}
@end
