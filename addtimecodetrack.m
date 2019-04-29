#import <Foundation/Foundation.h>
#import <QTKit/QTKit.h>
#import "TimecodeUtilities.h"

#pragma mark ---- the one, the only main ----

int main (int argc, const char * argv[]) {
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSUserDefaults *args = [NSUserDefaults standardUserDefaults];
    NSString *src = [args stringForKey:@"i"];
    NSString *tc = [args stringForKey:@"t"];
    
    //NSString *src = @"/Users/brian/Desktop/eits_tmp/20090124T060049Z.tmp2.mov";
    //NSString *tc = @"06:00:49:00";

    
    //**** Open Movie
    NSError *error = nil;
    QTMovie *qtMovie = [QTMovie movieWithFile:src error:&error]; 
    
    if (nil != error) {
        NSLog(@"Failed to open movie");
        return EXIT_FAILURE;
    }
    
    //*** Add Timecode track
    QTKitTC_AddTimeCodeTrackToQTMovie(qtMovie, tc);
    QTKitTC_ToggleTimeCodeDisplay(qtMovie);
    
    //**** Update the movie
    BOOL didSave = [qtMovie updateMovieFile];
    if (NO == didSave) {
        NSLog(@"Failed to save movie");
    }
    
    [pool drain];
    return EXIT_SUCCESS;
}