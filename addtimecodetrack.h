#import <QTKit/QTKit.h>

@interface MyController : NSObject
{
    QTMovie *mMovie;
    TimeCodeRecord  *mTimeCodeRecord;
    BOOL mDropFrame;
	BOOL m24HourMax;
	BOOL mNegativeOK;
	BOOL mNegative;
    BOOL mUseCounter;
}

- (void)doOpen:(NSString *filename) {
    
    
}