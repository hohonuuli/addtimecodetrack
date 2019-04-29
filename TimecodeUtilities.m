/*
 
 File: TimecodeUtilities.m
 
 Author: Brian Schlining
 
 */


#import "TimecodeUtilities.h"


/*
 Add a new Timecode track to a QTMovie
 */
OSStatus QTKitTC_AddTimeCodeTrackToQTMovie(QTMovie *inMovie,
                                           NSString *timecode)
{
    if (nil == inMovie) return paramErr;
    
    //**** Parse the timecode
    NSScanner *scanner = [NSScanner scannerWithString:timecode];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@":"]];
    int hours, minutes, seconds, frames;
    
    [scanner scanInt:&hours];
    [scanner scanInt:&minutes];
    [scanner scanInt:&seconds];
    [scanner scanInt:&frames];
    
    //**** Fill in the record
    TimeCodeRecord timeCodeRecord;
    
    timeCodeRecord.t.hours = (UInt8) hours;
    timeCodeRecord.t.minutes = (UInt8) minutes;                    // negative flag would go here
    timeCodeRecord.t.seconds = (UInt8) seconds;
    timeCodeRecord.t.frames =  (UInt8) frames;
    
    //**** DO the work
    
    
    Movie theQuickTimeMovie;
    Track theTCTrack;
    Media theTCMedia;
    MediaHandler theTCMediaHandler;
    
    OSStatus status;
    
    // movie size determines the width of the new timecode track
    NSSize movieSize = [[inMovie attributeForKey:QTMovieNaturalSizeAttribute] sizeValue];
    long   movieTimeScale = [[inMovie attributeForKey:QTMovieTimeScaleAttribute] longValue];
    
    theQuickTimeMovie = [inMovie quickTimeMovie];
    
    //**** Step 1. - Create Timecode Track and Media; get the Media Handler
    
    theTCTrack = NewMovieTrack(theQuickTimeMovie, FloatToFixed(movieSize.width), kTimeCodeTrackMaxHeight, kNoVolume);
    if (NULL == theTCTrack) return paramErr;
    
    theTCMedia = NewTrackMedia(theTCTrack, TimeCodeMediaType, movieTimeScale, NULL, 0);
    if (NULL == theTCMedia) return paramErr;
    
    theTCMediaHandler = GetMediaHandler(theTCMedia);
    if (NULL == theTCMediaHandler) return paramErr;
    
    //**** Step 2. - Fill in a timecode definition structure which becomes part of the timecode description
    // TODO: We're hardcoding these for now but will need to remove this for later stuff
    
    TimeCodeDef theTCDef;    
    long tcFlags = 0L;
    
    if (true) {
        if (true) tcFlags |= tcDropFrame;
        if (false) tcFlags |= tc24HourMax;
        if (false) tcFlags |= tcNegTimesOK;
    } else {
        tcFlags = tcCounter;
    }
    
    theTCDef.flags = tcFlags;
    theTCDef.fTimeScale = 2997;
    theTCDef.frameDuration = 100;
    theTCDef.numFrames = 30;
    
    //**** Step 4. - Setup timecode track geometry and display options depending on the selected font
    
    TCTextOptions theTextOptions;
    //    Str255           qdFontName;
    //    short            qdFontFace = 0;
    //    
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    NSFont *panelFont = [fontManager selectedFont];
    //    NSFontTraitMask fontFaceTraits = [fontManager traitsOfFont:panelFont];
    
    // get the font name so we can get the old font ID for the timecode text options
    //    CFStringGetPascalString((CFStringRef)[panelFont familyName], qdFontName, 256, kCFStringEncodingMacRoman);
    
    // convert NSFont traits to the older QuickDraw font face types for the timecode text options
    //    if (fontFaceTraits & NSItalicFontMask) qdFontFace |= italic;
    //    if (fontFaceTraits & NSBoldFontMask) qdFontFace |= bold;
    //    if (fontFaceTraits & NSCondensedFontMask) qdFontFace |= condense;
    //    if (fontFaceTraits & NSExpandedFontMask) qdFontFace |= extend;
    
    // get default display style options and set them appropriately    
    //    TCGetDisplayOptions(theTCMediaHandler, &theTextOptions);
    
    // FMGetFontFamilyFromName is deprecated but what else can we use, Timecode is stuck in the '90s
    //    theTextOptions.txFont = FMGetFontFamilyFromName(qdFontName); 
    // if we can't get a font ID just pick a default
    //    if (kInvalidFontFamily == theTextOptions.txFont) theTextOptions.txFont = kFontIDHelvetica;
    
    // The above code chokes on 10.5.6. Oh well, use a default font
    theTextOptions.txFont = kFontIDHelvetica;
    
    //    theTextOptions.txFace = qdFontFace;
    //    theTextOptions.txSize = (short)([panelFont pointSize]);
    
    TCSetDisplayOptions(theTCMediaHandler, &theTextOptions);
    
    // set track height based on font height
    // the timecode track will be placed spatially below all other tracks
    float fontHeight = ([panelFont ascender] - [panelFont descender]);
    SetTrackDimensions(theTCTrack, FloatToFixed(movieSize.width), FloatToFixed(fontHeight + 2.0));
    
    MatrixRecord theTrackMatrix;
    GetTrackMatrix(theTCTrack, &theTrackMatrix);
    TranslateMatrix(&theTrackMatrix, 0, FloatToFixed(movieSize.height));
    SetTrackMatrix(theTCTrack, &theTrackMatrix);    
    
    // enable the track and set the flags to hide the timecode
    SetTrackEnabled(theTCTrack, true);
    TCSetTimeCodeFlags(theTCMediaHandler, tcdfShowTimeCode, tcdfShowTimeCode);
    
    //**** Step 5. - Add the media sample
    
    TimeCodeDescriptionHandle theTCSampleDescriptionH = NULL;
    
    status = BeginMediaEdits(theTCMedia);
    if (noErr != status) goto bail;
    
    //**** Step 5a. - create and configure the timecode sample
    
    theTCSampleDescriptionH = (TimeCodeDescriptionHandle)NewHandleClear(sizeof(TimeCodeDescription));
    if (NULL == theTCSampleDescriptionH) goto bail;
    
    (**theTCSampleDescriptionH).descSize = sizeof(TimeCodeDescription);
    (**theTCSampleDescriptionH).dataFormat = TimeCodeMediaType;
    (**theTCSampleDescriptionH).timeCodeDef = theTCDef;
    
    // set the source identification information - this information for a timecode track
    // is stored in a user data item of type TCSourceRefNameType but is not mandatory
    UserData theSourceIDUserData;
    
    status = NewUserData(&theSourceIDUserData);
    if (noErr == status) {
        //        Handle theDataHandle = NULL;
        //        //ConstStringPtr theSourceName = [inController sourceNamePString];
        //        // FIXME: this is causing errors I think
        //        ConstStringPtr *theSourceName = [@"UTC Time" UTF8String];
        //        
        //        PtrToHand(&theSourceName[1], &theDataHandle, theSourceName[0]);
        //        status = AddUserDataText(theSourceIDUserData, theDataHandle, TCSourceRefNameType, 1, langEnglish);
        //        if (noErr == status) TCSetSourceRef(theTCMediaHandler, theTCSampleDescriptionH, theSourceIDUserData);
        //        
        //        free((void *)theSourceName);
        //        DisposeHandle(theDataHandle);
        //        DisposeUserData(theSourceIDUserData);
    }
    
    //**** Step 5b. - add a sample to the timecode track - each sample in a timecode track provides timecode information
    //                for a span of movie time; here, we add a single sample that spans the entire movie duration
    //    The sample data contains a single frame number that identifies one or more content frames that use the
    //  timecode; this value (a long integer) identifies the first frame that uses the timecode
    long theMediaSample = 0L;
    
    status = TCTimeCodeToFrameNumber(theTCMediaHandler, &theTCDef, &timeCodeRecord, &theMediaSample);
    if (noErr != status) goto bail;
    
    // the timecode media sample must be big-endian
    theMediaSample = EndianS32_NtoB(theMediaSample);
    
    QTTime movieDuration = [inMovie duration];
    // since we created the track with the same timescale as the movie we don't need to convert the duration
    
    status = AddMediaSample2(theTCMedia, (UInt8 *)(&theMediaSample), sizeof(long), movieDuration.timeValue, 0, (SampleDescriptionHandle)theTCSampleDescriptionH, 1, 0, NULL);
    if (noErr != status) goto bail;
    
    status = EndMediaEdits(theTCMedia);
    if (noErr != status) goto bail;
    
    status = InsertMediaIntoTrack(theTCTrack, 0, 0, movieDuration.timeValue, fixed1);
    if (noErr != status) goto bail;
    
    //**** Step 6. - are we done yet? nope, create a track reference from the target track to the timecode track
    //               here we use the first video media track type as the target track
    
    NSArray *videoTracks = [inMovie tracksOfMediaType:QTMediaTypeVideo];
    QTTrack *firstVideoTrack = [videoTracks objectAtIndex:0];
    
    status = AddTrackReference([firstVideoTrack quickTimeTrack], theTCTrack, kTrackReferenceTimeCode, NULL);
    
bail:
    if (NULL != theTCSampleDescriptionH) DisposeHandle((Handle)theTCSampleDescriptionH);
    
    if (noErr != status) {
        // well, something went wrong so delete the track and media I guess - bummers!
        if (theTCMedia) DisposeTrackMedia(theTCMedia);
        if (theTCTrack) DisposeMovieTrack(theTCTrack);
    }
    
    return status;
}

/*
 Delete the Timecode tracks
 */
void QTKitTC_DeleteTimeCodeTracks(QTMovie *inMovie)
{
	if (nil == inMovie) return;
    
	QTTrack *tcTrack = QTKitTC_QTMovieGetFirstTimecodeTrack(inMovie);
	
	while (nil != tcTrack) {
		// while it is not specifically a requirement that we delete all the references to this track
		// (as DisposeMovieTrack will zero out the trackID), doing so will keep the 'tref' atom from 
		// containing a bunch of zero entries and growing larger if a number of references were added
		// to tracks being added then deleted -- there shouldn't be anything wrong with either approach
		// calling QTKitTC_DeleteAllReferencesToTrack or commenting it out should not change the behavior
		// of the saved movie
		QTKitTC_DeleteAllReferencesToQTTrack([inMovie tracks], tcTrack);
		DisposeMovieTrack([tcTrack quickTimeTrack]);
		
		tcTrack = QTKitTC_QTMovieGetFirstTimecodeTrack(inMovie);
	}
}

/*
 Return the current Timecode as an NSString the caller needs to release
 */
NSString* QTKitTC_GetCurrentTimeCodeString(QTMovie *inMovie)
{
	if (nil == inMovie) return nil;
    
	MediaHandler theHandler = QTKitTC_QTMovieGetTimeCodeMediaHandler(inMovie);
	if (theHandler != NULL) {
		TimeCodeDef	   timecodeDef;
		TimeCodeRecord timecodeRec;
		HandlerError   status;
        
		// get the timecode for the current movie time
		status = TCGetCurrentTimeCode(theHandler, NULL, &timecodeDef, &timecodeRec, NULL);
		if (status == noErr) {
			Str255 aString;
			
			// convert a time value into a pascal string (HH:MM:SS:FF)
			status = TCTimeCodeToString(theHandler, &timecodeDef, &timecodeRec, aString);
			if (status == noErr) {
				return (NSString*)CFStringCreateWithPascalString(kCFAllocatorDefault, aString, kCFStringEncodingMacRoman);
			}
		}
	}
	
	return nil;
}

/*
 Return the Source Name as an NSString the caller needs to release
 */
NSString* QTKitTC_GetTimeCodeSourceString(QTMovie *inMovie)
{
	if (nil == inMovie) return nil;
    
	MediaHandler theHandler = QTKitTC_QTMovieGetTimeCodeMediaHandler(inMovie);
	if (theHandler != NULL) {
		UserData	 userData;
		HandlerError status;
        
		// get the timecode source for the current movie time
		// the last field is a pointer to that is to receive a handle containing the source information as a
		// UserDataRecord structure -- it is your responsibility to dispose of this structure when you are done with it
		status = TCGetCurrentTimeCode(theHandler, NULL, NULL, NULL, &userData);
		if (status == noErr) {
			Str255 aString = "\pNo Source Name";
			Handle theSourceHandle = NewHandleClear(0);
			
			GetUserDataText(userData, theSourceHandle, TCSourceRefNameType, 1, langEnglish);
			if (GetHandleSize(theSourceHandle) > 0) {
				BlockMoveData(*theSourceHandle, &aString[1], GetHandleSize(theSourceHandle));
				aString[0] = GetHandleSize(theSourceHandle);
			}
			
			if (NULL != theSourceHandle) DisposeHandle(theSourceHandle);
			if (NULL != userData) DisposeUserData(userData);
			
			return (NSString*)CFStringCreateWithPascalString(kCFAllocatorDefault, aString, kCFStringEncodingMacRoman);
		}
	}
	
	return nil;
}

/*
 Toggle the Timecode disply
 */
void QTKitTC_ToggleTimeCodeDisplay(QTMovie *inMovie)
{
	if (nil == inMovie) return;
	
	QTTrack *tcTrack;
	MediaHandler theMediaHandler;
	long flags = 0L;
	
	tcTrack = QTKitTC_QTMovieGetFirstTimecodeTrack(inMovie);
	if (nil == tcTrack) return;
    
	theMediaHandler = QTKitTC_QTMovieGetTimeCodeMediaHandler(inMovie);
	if (NULL != theMediaHandler) {
        
		// toggle the show-timecode flag
		TCGetTimeCodeFlags(theMediaHandler, &flags);
		flags ^= tcdfShowTimeCode;
		TCSetTimeCodeFlags(theMediaHandler, flags, tcdfShowTimeCode);
        
        // set the track enabled state
		[tcTrack setEnabled:(BOOL)flags];
	}
}

/*
 Does the QTMovie have a Timecode track type
 */
BOOL QTKitTC_QTMovieHasTimeCodeTrack(QTMovie *inMovie)
{
	NSArray *trackArray = [inMovie tracksOfMediaType:QTMediaTypeTimeCode];
    
	if ([trackArray count] > 0) return YES;
    
    return NO;
}

/*
 Return the first Timecode track as a QTTrack
 */
QTTrack* QTKitTC_QTMovieGetFirstTimecodeTrack(QTMovie *inMovie)
{
    NSArray *trackArray = [inMovie tracksOfMediaType:QTMediaTypeTimeCode];
	
	if ([trackArray count] != 0) return [trackArray objectAtIndex:0];
    
	return nil;
}

/*
 Return the Timecode Media Mediahandler
 */
MediaHandler QTKitTC_QTMovieGetTimeCodeMediaHandler(QTMovie *inMovie)
{
	QTTrack *tcTrack = QTKitTC_QTMovieGetFirstTimecodeTrack(inMovie);
	if (nil == tcTrack) return NULL;
	
    QTMedia *tcMedia = [tcTrack media];
	if (nil == tcMedia) return NULL;
    
	return GetMediaHandler([tcMedia quickTimeMedia]);
}

/*
 Delete all the track reference identifiers referencing the source track
 */
OSStatus QTKitTC_DeleteAllReferencesToQTTrack(NSArray *inAllMovieTracks, QTTrack *inSourceTrack)
{
	if (nil == inAllMovieTracks || nil == inSourceTrack) return paramErr;
	
	NSEnumerator *enumerator = [inAllMovieTracks objectEnumerator];
	QTTrack *aTrack = nil;
	OSStatus status = noErr;
	
	// iterate thru all the movies tracks which are not the source track being referenced (i.e. different from the specified source track)
	while (aTrack = [enumerator nextObject]) {
		if (![aTrack isEqual:inSourceTrack]) {
			Track  theCurrentMovieTrack = [aTrack quickTimeTrack];
			OSType theTrackReferenceType = 0L;
			
			// iterate thru all track reference types contained in the current movie track
			theTrackReferenceType = GetNextTrackReferenceType(theCurrentMovieTrack, theTrackReferenceType);
			while (theTrackReferenceType != 0L) {
				UInt32 theTrackReferenceCount = GetTrackReferenceCount(theCurrentMovieTrack, theTrackReferenceType);
				UInt32 theTrackReferenceIndex;
				
				// iterate thru all track references of the current type
				// note that we count down to 1, since DeleteTrackReference will cause
				// any higher-indexed track references to be renumbered
				for (theTrackReferenceIndex = theTrackReferenceCount; theTrackReferenceIndex >= 1; theTrackReferenceIndex--) {
					Track theTrackReference = NULL;
					
					theTrackReference = GetTrackReference(theCurrentMovieTrack, theTrackReferenceType, theTrackReferenceIndex);
					if (theTrackReference == [inSourceTrack quickTimeTrack]) {
						status = DeleteTrackReference(theCurrentMovieTrack, theTrackReferenceType, theTrackReferenceIndex);
					}
				}
				
				theTrackReferenceType = GetNextTrackReferenceType(theCurrentMovieTrack, theTrackReferenceType);
			}
		}
	}
	
	return status;
}