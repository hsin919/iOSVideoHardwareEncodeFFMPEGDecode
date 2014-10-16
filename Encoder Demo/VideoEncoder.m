//
//  VideoEncoder.m
//  Encoder Demo
//
//  Created by Geraint Davies on 14/01/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "VideoEncoder.h"

@implementation VideoEncoder

@synthesize path = _path;

+ (VideoEncoder*) encoderForPath:(NSString*) path Height:(int) height andWidth:(int) width
{
    VideoEncoder* enc = [VideoEncoder alloc];
    [enc initPath:path Height:height andWidth:width];
    NSLog(@"new VideoEncoder with path:%@", path);
    return enc;
}


- (void) initPath:(NSString*)path Height:(int) height andWidth:(int) width
{
    self.path = path;
    
    [[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
    NSURL* url = [NSURL fileURLWithPath:self.path];
    
    _writer = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeMPEG4 error:nil];
    NSDictionary* settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              // H.264 encoder
                              AVVideoCodecH264, AVVideoCodecKey,
                              [NSNumber numberWithInt: width], AVVideoWidthKey,
                              [NSNumber numberWithInt:height], AVVideoHeightKey,
                              [NSDictionary dictionaryWithObjectsAndKeys:
                                    @NO, AVVideoAllowFrameReorderingKey,
                               AVVideoProfileLevelH264High41, AVVideoProfileLevelKey,
                               AVVideoH264EntropyModeCAVLC, AVVideoH264EntropyModeKey,
                               //@0.1, AVVideoMaxKeyFrameIntervalDurationKey,
                               nil],
                                    AVVideoCompressionPropertiesKey,
                              nil];
    // 利用 AVFundation encode
    _writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
    
    _writerInput.expectsMediaDataInRealTime = YES;
    [_writer addInput:_writerInput];
}

- (void) finishWithCompletionHandler:(void (^)(void))handler
{
    [_writer finishWritingWithCompletionHandler: handler];
}

- (BOOL) encodeFrame:(CMSampleBufferRef) sampleBuffer
{
    NSDictionary *test = [_writerInput.outputSettings objectForKey:AVVideoCompressionPropertiesKey];
    
    NSLog(@">>>>>>%@", [test objectForKey:AVVideoAllowFrameReorderingKey]);
    if (CMSampleBufferDataIsReady(sampleBuffer))
    {
        if (_writer.status == AVAssetWriterStatusUnknown)
        {
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            [_writer startWriting];
            [_writer startSessionAtSourceTime:startTime];
        }
        if (_writer.status == AVAssetWriterStatusFailed)
        {
            NSLog(@"writer error %@", _writer.error.localizedDescription);
            return NO;
        }
        if (_writerInput.readyForMoreMediaData == YES)
        {
            // 把影像encode成h264到檔案
            [_writerInput appendSampleBuffer:sampleBuffer];
            return YES;
        }
    }
    return NO;
}

@end
