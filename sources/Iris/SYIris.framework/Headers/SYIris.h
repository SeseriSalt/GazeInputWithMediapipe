#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@class Landmark;
@class SYIris;

@protocol SYIrisDelegate <NSObject>
- (void)irisTracker: (SYIris*)irisTracker didOutputLandmarks: (NSArray<Landmark *> *)landmarks;
- (void)irisTracker: (SYIris*)irisTracker didOutputPixelBuffer: (CVPixelBufferRef)pixelBuffer;
@end

@interface SYIris : NSObject
- (instancetype)init;
- (void)startGraph;
- (void)processVideoFrame: (CVPixelBufferRef)imageBuffer;
@property (weak, nonatomic) id <SYIrisDelegate> delegate;
@end

@interface Landmark: NSObject
@property(nonatomic, readonly) float x;
@property(nonatomic, readonly) float y;
@property(nonatomic, readonly) float z;
@end