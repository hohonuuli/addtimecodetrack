/*
 
 File: TimecodeUtilities.h
 
 Author: Brian Schlining
 
*/

#import <QTKit/QTKit.h>
#include <QuickTime/QuickTime.h>

#define kTimeCodeTrackMaxHeight (320 << 16) // max height of timecode track

OSStatus 		QTKitTC_AddTimeCodeTrackToQTMovie(QTMovie *inMovie, NSString *timecode);
void 			QTKitTC_DeleteTimeCodeTracks(QTMovie *inMovie);
NSString* 		QTKitTC_GetCurrentTimeCodeString(QTMovie *inMovie);
NSString* 		QTKitTC_GetTimeCodeSourceString(QTMovie *inMovie);
QTTrack* 		QTKitTC_QTMovieGetFirstTimecodeTrack(QTMovie *inMovie);
void 			QTKitTC_ToggleTimeCodeDisplay(QTMovie *inMovie);
MediaHandler	QTKitTC_QTMovieGetTimeCodeMediaHandler(QTMovie *inMovie);
BOOL 			QTKitTC_QTMovieHasTimeCodeTrack(QTMovie *inMovie);
OSStatus 		QTKitTC_DeleteAllReferencesToQTTrack(NSArray *inTracks, QTTrack *inTrack);