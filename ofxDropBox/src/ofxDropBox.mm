


#include "ofxDropBox.h"
#import <DropboxSDK/DropboxSDK.h>



ofxDropBox::ofxDropBox() {
    isAuthenticated = false;
    uploadsComplete = false;
    downloadsComplete = false;
    
    // we want to know when something has been launched with a url
    ofxiPhoneAlerts.addListener(this);
    
    // setup objc style delegate
    dropBoxDelegate = [[ofxDropBoxDelegate alloc] init:	this ];
}


ofxDropBox::~ofxDropBox() {
    [dropBoxDelegate release];
}

void ofxDropBox::startSession(string appKey, string appSecret, bool useDBRootAppFolder) {
        
    DBSession* dbSession = [[[DBSession alloc]  
                             initWithAppKey:ofxStringToNSString(appKey)
                             appSecret:ofxStringToNSString(appSecret)
                             root:(useDBRootAppFolder) ? kDBRootAppFolder : kDBRootDropbox] // either kDBRootAppFolder or kDBRootDropbox
                            autorelease];
    dbSession.delegate = dropBoxDelegate;
    [DBRequest setNetworkRequestDelegate:dropBoxDelegate];
    [DBSession setSharedSession:dbSession];
    
    // check if already authenticated- should only need auth once
    if ([[DBSession sharedSession] isLinked]) {
        notifyAuthorised();
    }
}

void ofxDropBox::notifyAuthorised(bool success) {
    
    isAuthenticated = success;
    ofNotifyEvent(onAuthorisedEvent, isAuthenticated, this);
}


void ofxDropBox::linkAccount() {
    
    // connect to users account through dropbox app or mobile browser (safari)
    if (![[DBSession sharedSession] isLinked]) {
        NSLog(@"\n\n DropBox is not linked, launching native DropBox app or browser\n\n");
        [[DBSession sharedSession] linkFromController:ofxiPhoneGetViewController()];
    } 
}

void ofxDropBox::unlinkAccount() {
    
    NSLog(@"\n\n Unlinking DropBox\n\n");
    if ([[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] unlinkAll];
        notifyAuthorised(false);
    }
}

void ofxDropBox::uploadFile(string filePath) {
    
    uploadsComplete = false; 
    
    // add item to queue
    NSString *nFilePath = ofxStringToNSString(filePath);
    [[dropBoxDelegate uploadQueue] addObject:nFilePath];
    dropBoxDelegate.isUploading = YES;
    
    // load meta data before starting upload if haven't already 
    // hasMetaDataUpdated resets when upload count & download count = 0
    if(![dropBoxDelegate hasMetaDataUpdated]) {
        dropBoxDelegate.hasMetaDataUpdated = YES;        
        [[dropBoxDelegate restClient] loadMetadata:@"/"];
    } 
}

// when a full queue is uploaded from delegate send notification
void ofxDropBox::notifyQueueUploaded(bool success) {
    
    uploadsComplete = success;
    ofNotifyEvent(onQueueUploadEvent, uploadsComplete, this);
}

void ofxDropBox::downloadFile(string filePath) {
    
    downloadsComplete = false; 
    NSLog(@"do download ");
    
    // add item to queue
    NSString *nFilePath = ofxStringToNSString(filePath);
    [[dropBoxDelegate downloadQueue] addObject:nFilePath];
    dropBoxDelegate.isDownloading = YES;
    
    // load meta data before starting download if haven't already 
    // hasMetaDataUpdated resets when upload count & download count = 0
    if(![dropBoxDelegate hasMetaDataUpdated]) {
        dropBoxDelegate.hasMetaDataUpdated = YES;        
        [[dropBoxDelegate restClient] loadMetadata:@"/"];
    } 
}

// when a full queue is uploaded from delegate send notification
void ofxDropBox::notifyQueueDownloaded(bool success) {
    
    downloadsComplete = success;
    ofNotifyEvent(onQueueDownloadEvent, downloadsComplete, this);
}



// only gets called once when app launches dropbox as app or in browser
void ofxDropBox::launchedWithURL(string url)
{    
    NSURL* nsUrl = [ [ NSURL alloc ] initWithString: ofxStringToNSString(url) ];
    if ([[DBSession sharedSession] handleOpenURL:nsUrl]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked successfully! At this point you can start making API calls");
            notifyAuthorised();
        }
    }
}

// activity indicator stuff
void ofxDropBox::showBusyIndicator() {
    [[dropBoxDelegate busyAnimation] startAnimating];
}

void ofxDropBox::hideBusyIndicator() {
    [[dropBoxDelegate busyAnimation] stopAnimating];
}


//--------------------------------------------------------------
@implementation ofxDropBoxDelegate

@synthesize busyAnimation;
@synthesize uploadQueue;
@synthesize downloadQueue;
@synthesize dbMetaData;
@synthesize hasMetaDataUpdated;
@synthesize isUploading;
@synthesize isDownloading;

//--------------------------------------------------------------
- (id) init :(ofxDropBox *)dbCpp {
	if(self = [super init])	{			
		NSLog(@"ofxDropBoxDelegate initiated");
        
        // ref to OF instance
        dropBoxCpp = dbCpp;
        
        //dropBoxCpp = dbCpp;
        uploadQueue = [[NSMutableArray alloc]init];
        downloadQueue = [[NSMutableArray alloc]init];
        dbMetaData = [[NSMutableArray alloc]init];
        hasMetaDataUpdated = NO;
        isUploading = NO;
        isDownloading = NO;
        
        // create an acitivty indicator view for when stuff is happening
        busyAnimation = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        busyAnimation.frame = CGRectMake(0, 0, ofGetWidth(), ofGetHeight());
        [busyAnimation stopAnimating];        
        [ofxiPhoneGetGLParentView() addSubview:busyAnimation];
	}
	return self;
}

- (void) dealloc {
    [busyAnimation stopAnimating]; 
    [busyAnimation removeFromSuperview];
    [busyAnimation release];
    busyAnimation = nil;
    
    [uploadQueue removeAllObjects];
    [uploadQueue release];
    uploadQueue = nil;
    
    [downloadQueue removeAllObjects];
    [downloadQueue release];
    downloadQueue = nil;
    
    [dbMetaData removeAllObjects];
    [dbMetaData release];
    dbMetaData = nil;
    
    [restClient release];
    restClient = nil;
    
    dropBoxCpp = nil;
    
    [relinkUserId release];
    relinkUserId = nil;
    
    [super dealloc];
}

- (DBRestClient*)restClient {
    if (restClient == nil) {
        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    return restClient;
}

// dropbox meta info - use this when uploading and downloading
- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    
    if (metadata.isDirectory) {
        
        // save metadata        
        [dbMetaData removeAllObjects]; 
        [dbMetaData release];
        dbMetaData = [NSMutableArray arrayWithArray: metadata.contents];
        [dbMetaData retain];
    }
    
    // once meta data is loaded, start uploading or downloading files from queue
    if(isUploading) {
        [self uploadQueueWithMeta];
    } else if(isDownloading) {
        [self downloadQueueWithMeta];
    }    
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
    
    NSLog(@"Error loading metadata: %@", error);
}


// dropbox uploads
- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
    if([uploadQueue count] == 0) {
        if([downloadQueue count] == 0) {
            hasMetaDataUpdated = NO; // reset- meta can be checked again at the beginning of each queue
        } else {
            if(isDownloading) [self downloadQueueWithMeta]; // start the download queue if required
        }
        
        isUploading = NO;
        dropBoxCpp->notifyQueueUploaded();
    } else {
        // continue uploading queue
        [self uploadQueueWithMeta];
    }
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    NSLog(@"*File upload failed with error - %@", error);
    if([uploadQueue count] == 0) {
        if([downloadQueue count] == 0) {
            hasMetaDataUpdated = NO; // reset- meta can be checked again at the beginning of each queue
        } else {
            if(isDownloading) [self downloadQueueWithMeta]; // start the download queue if required
        }
        isUploading = NO;
        dropBoxCpp->notifyQueueUploaded(false);
    } else {
        // continue uploading queue
        [self uploadQueueWithMeta];
    }
}

- (void) uploadQueueWithMeta {
    
    NSString *fileToUpload = [uploadQueue objectAtIndex:0];
    NSString *fileRev = nil;
    
    // see if file already exists
    for (DBMetadata *file in dbMetaData) {
        
        //NSLog(@"\nfilename: %@, revision: %@, date: %@", file.filename, file.rev, file.lastModifiedDate);
        if( [fileToUpload isEqualToString:file.filename]) {

            // file already exists - upload with revision & don't make copy
            fileRev = file.rev;
            break;
        }
    }
    
    // upload file into default folder in your dropbox -eg. DropBox/Apps/YourApp
    NSString *localPath = [[NSBundle mainBundle] pathForResource:[[fileToUpload lastPathComponent] stringByDeletingPathExtension]
                                                          ofType:[fileToUpload pathExtension] ];
    NSString *destDir = @"/"; 
    [[self restClient] uploadFile:fileToUpload toPath:destDir
                    withParentRev:fileRev fromPath:localPath];
    
    // delete item from queue
    [uploadQueue removeObjectAtIndex:0];
}

// dropbox downloads
- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath {
    
    NSLog(@"*File downloaded into path: %@", localPath);
    if([downloadQueue count] == 0) {
        if([uploadQueue count] == 0) {
            hasMetaDataUpdated = NO; // reset- meta can be checked again at the beginning of each queue
        } else {
            if(isUploading) [self uploadQueueWithMeta]; // start the download queue if required
        }
        
        isDownloading = NO;
        dropBoxCpp->notifyQueueDownloaded();
    } else {
        // continue downloading queue
        [self downloadQueueWithMeta];
    }
}

- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
    NSLog(@"There was an error downloading the file - %@", error);
    if([downloadQueue count] == 0) {
        if([uploadQueue count] == 0) {
            hasMetaDataUpdated = NO; // reset- meta can be checked again at the beginning of each queue
        } else {
            if(isUploading) [self uploadQueueWithMeta]; // start the download queue if required
        }
        
        isDownloading = NO;
        dropBoxCpp->notifyQueueDownloaded(false);
    } else {
        // continue downloading queue
        [self downloadQueueWithMeta];
    }
}

- (void) downloadQueueWithMeta {
    
    NSString *fileToDownload = [downloadQueue objectAtIndex:0];
    
    // make sure file exists in dropbox
    for (DBMetadata *file in dbMetaData) {
        
        NSLog(@"\nfilename: %@, revision: %@, date: %@, path: %@", file.filename, file.rev, file.lastModifiedDate, file.path);
        if( [fileToDownload isEqualToString:file.filename]) {
            
            // save to documents
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileToDownload];

            [[self restClient] loadFile:file.path intoPath:filePath];
            
            // delete item from queue
            [downloadQueue removeObjectAtIndex:0];
            return;
        }
    }
    
    // should not get here unless the file doesn't exist in users dropbox.
    // generate same loadFileFailedWithError error anyway
    NSLog(@"\n\n* Error: file not found. Copy an image named %@ to your 'Dropbox/Apps/YourApp'", fileToDownload);
    [downloadQueue removeObjectAtIndex:0]; // delete from queue anyway
    if([downloadQueue count] == 0) {
        if([uploadQueue count] == 0) {
            hasMetaDataUpdated = NO; // reset- meta can be checked again at the beginning of each queue
        } else {
            if(isUploading) [self uploadQueueWithMeta]; // start the download queue if required
        }
        
        isDownloading = NO;
        dropBoxCpp->notifyQueueDownloaded(false);
    } else {
        // continue downloading queue
        [self downloadQueueWithMeta];
    }
}

// this was in the dropbox ios examples, but don't think it's required?
/*#pragma mark -
 #pragma mark UIAlertViewDelegate methods
 
 - (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {
 NSLog(@"\n\n**** some alert \n\n");
 if (index != alertView.cancelButtonIndex) {
 [[DBSession sharedSession] linkUserId:relinkUserId fromController:ofxiPhoneGetViewController()];
 }
 [relinkUserId release];
 relinkUserId = nil;
 }*/


#pragma mark -
#pragma mark DBSessionDelegate methods

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId {
    NSLog(@"\n\n**** session auth failed \n\n");
	relinkUserId = [userId retain];
	[[[[UIAlertView alloc] 
	   initWithTitle:@"Dropbox Session Ended" message:@"Do you want to relink?" delegate:self 
	   cancelButtonTitle:@"Cancel" otherButtonTitles:@"Relink", nil]
	  autorelease]
	 show];
}

#pragma mark -
#pragma mark DBNetworkRequestDelegate methods

static int outstandingRequests;

- (void)networkRequestStarted {
	outstandingRequests++;
	if (outstandingRequests == 1) {
        [busyAnimation startAnimating];
	}
}

- (void)networkRequestStopped {
	outstandingRequests--;
	if (outstandingRequests == 0) {
        [busyAnimation stopAnimating];
	}
}

@end


// commenting these out - originally i was overriding ofxiPhoneAppDelegate with categories
/*
 Overriding the handleOpenURL from ofxiPhoneAppDelegate with categories
 - ref: http://forum.openframeworks.cc/index.php/topic,9609.0.html
 - have not implemented 'method swizzling' yet, just copied original code inside method.
 - 
 
 */
// ----------------------------------------------------------------
//@implementation ofxiPhoneAppDelegate (myDropBoxCategory)  
//
//- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
//    NSLog(@"\n\nOverriding handleOpenURL with category. Url: \n\n%@\n\n", url);
//    /*if ([[DBSession sharedSession] handleOpenURL:url]) {
//        if ([[DBSession sharedSession] isLinked]) {
//            NSLog(@"App linked successfully!");
//            // At this point you can start making API calls
//        }
//        return YES;
//    }*/
//    
//	NSString *urlData = [url absoluteString];
//	const char * response = [urlData UTF8String];
//	ofxiPhoneAlerts.launchedWithURL(response);
//	return YES;
//}
//@end  

//@implementation ofxiPhoneAppDelegate (myDropBoxCategory)  
//- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//    
//    
//    [self applicationDidFinishLaunching:application];
//    
//    NSURL *launchURL = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
//	NSInteger majorVersion = 
//    [[[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."] objectAtIndex:0] integerValue];
//	if (launchURL && majorVersion < 4) {
//		// Pre-iOS 4.0 won't call application:handleOpenURL; this code is only needed if you support
//		// iOS versions 3.2 or below
//        
//		[self application:application handleOpenURL:launchURL];
//		return NO;
//	}
//    
//    return YES;
//}
//@end  