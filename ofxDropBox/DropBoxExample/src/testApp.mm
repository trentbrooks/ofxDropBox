#include "testApp.h"

//--------------------------------------------------------------
void testApp::setup(){	

    iPhoneSetOrientation(OFXIPHONE_ORIENTATION_PORTRAIT);	
	ofBackground(127,127,127);
    ofEnableAlphaBlending();
        
    // file we download from dropbox
    imageLoaded = false;
    
    // setup dropbox with listeners
    dropBox = new ofxDropBox(); 
    ofAddListener(dropBox->onAuthorisedEvent, this, &testApp::onDropBoxAuthorised);
    ofAddListener(dropBox->onQueueUploadEvent, this, &testApp::onDropBoxUpload); 
    ofAddListener(dropBox->onQueueDownloadEvent, this, &testApp::onDropBoxDownload); 
    
    // connect to dropbox- get key + secret from dropbox website- https://www.dropbox.com/developers/apps
    string appKey = "APP_KEY"; // this also needs to be added to the 'ofxiphone-info.plist'- see ofxDropbox.h for instructions
    string appSecret = "APP_SECRET";
    dropBox->startSession(appKey, appSecret);

}

// dropbox events
void testApp::onDropBoxAuthorised(const void * sender, bool &success) {
    
    cout << "1. Dropbox authenticated: " << success << "\n" << endl;    
}

void testApp::onDropBoxDownload(const void * sender, bool &success) {
    
    cout << "2. Image downloaded to app: " << success << "\n" << endl;
    
    // once image is downloaded documents folder, load it into our OF app
    img.loadImage(ofxiPhoneGetDocumentsDirectory() + "test.jpg");
    imageLoaded = true;
}

void testApp::onDropBoxUpload(const void * sender, bool &success) {
    
    cout << "3. Multiple files uploaded to dropbox: " << success << "\n" << endl;
}


//--------------------------------------------------------------
void testApp::update(){

}

//--------------------------------------------------------------
void testApp::draw(){
	
    ofBackground(40);
    
    int buttonHeight = ofGetHeight() * .25;
    int buttonWidth = ofGetWidth();
    int xPos = 0;
    int yPos = 0;
    int textOffset = 20;// * retinaScale;
    
    // yellow box for authorise
    ofSetColor(255, 255, 0);
    ofRect(xPos, yPos, buttonWidth, buttonHeight);
    ofDrawBitmapStringHighlight("1. Link dropbox", textOffset + xPos, textOffset + yPos);
    ofSetColor(0);
    ofDrawBitmapString("- Opens a DropBox login \n- Only needs authorisation once", textOffset + xPos, textOffset + yPos + textOffset);
    if(dropBox->isAuthenticated) {
        ofSetColor(255, 255, 0, 180);
        ofRect(xPos, yPos, buttonWidth, buttonHeight);
        ofDrawBitmapStringHighlight("Done", textOffset + xPos, buttonHeight - textOffset + yPos);
    }
        
    // pink box for download
    ofSetColor(255, 0, 255);
    yPos = buttonHeight;
    ofRect(xPos, yPos, buttonWidth, buttonHeight);
    ofDrawBitmapStringHighlight("2. Download + display file", textOffset + xPos, textOffset + yPos);
    ofSetColor(0);
    ofDrawBitmapString("- Make sure the file 'test.jpg'\n  is in your DropBox/Apps/YourApp \n  folder before downloading", textOffset + xPos, textOffset + yPos + textOffset);    
    if(dropBox->downloadsComplete) {
        ofSetColor(255, 0, 255, 180);
        ofRect(xPos, yPos, buttonWidth, buttonHeight);
        
        // draw downloaded image
        if(imageLoaded) {
            ofSetColor(255);
            img.draw(ofGetWidth() * .5 + (-buttonHeight * .5), yPos, buttonHeight, buttonHeight);
        }
        
        ofDrawBitmapStringHighlight("Done", textOffset + xPos, buttonHeight - textOffset + yPos);
    }
    
    // blue box for upload
    ofSetColor(0, 255, 255);
    yPos = buttonHeight * 2;
    ofRect(xPos, yPos, buttonWidth, buttonHeight);
    ofDrawBitmapStringHighlight("3. Upload multiple files", textOffset + xPos, textOffset + yPos);
    ofSetColor(0);
    ofDrawBitmapString("- Uploads go from iPhone app folder\n  into your DropBox\n- Files: 'Default.png, sample.csv'", textOffset + xPos, textOffset + yPos + textOffset);
    if(dropBox->uploadsComplete) {
        ofSetColor(0, 255, 255, 180);
        ofRect(xPos, yPos, buttonWidth, buttonHeight);
        ofDrawBitmapStringHighlight("Done", textOffset + xPos, buttonHeight - textOffset + yPos);
    }
    
    // red box to unlink account
    ofSetColor(255, 0, 0);
    yPos = buttonHeight * 3;
    ofRect(xPos, yPos, buttonWidth, buttonHeight);
    ofDrawBitmapStringHighlight("4. Unlink dropbox", textOffset + xPos, textOffset + yPos);
    ofSetColor(0);
    ofDrawBitmapString("- Unlink to allow reauthorisation", textOffset + xPos, textOffset + yPos + textOffset);
    if(!dropBox->isAuthenticated) {
        ofSetColor(255, 0, 0, 180);
        ofRect(xPos, yPos, buttonWidth, buttonHeight);
        ofDrawBitmapStringHighlight("Done", textOffset + xPos, buttonHeight - textOffset + yPos);
    }
}



//--------------------------------------------------------------
void testApp::exit(){

}

//--------------------------------------------------------------
void testApp::touchDown(ofTouchEventArgs & touch){
}

//--------------------------------------------------------------
void testApp::touchMoved(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void testApp::touchUp(ofTouchEventArgs & touch){

    // see which button area we touched
    int buttonHeight = ofGetHeight() * .25;
    if(touch.y < buttonHeight) {
        
        // link button
        if(!dropBox->isAuthenticated) {
            dropBox->linkAccount();
        } else {
            cout << "Dropbox already authorised. Press '4. Unlink DropBox' to allow relinking" << endl;
        }
        
    } else if(touch.y < buttonHeight * 2) {
        cout << "dow dow" << endl;
        // download button
        if(dropBox->isAuthenticated && !dropBox->downloadsComplete) {
            // this file must exist in your dropbox folder
            dropBox->downloadFile("test.jpg"); 
        } else {
            cout << "Dropbox not authorised. Press '1. Link DropBox'" << endl;
        }
        
    } else if(touch.y < buttonHeight * 3) {
        
        // upload button
        if(dropBox->isAuthenticated && !dropBox->uploadsComplete) {
            // uploads from iPhone app folder to DropBox/Apps/YourApp/
            dropBox->uploadFile("Default.png"); 
            dropBox->uploadFile("sample.csv"); 
        } else {
            cout << "Dropbox not authorised. Press '1. Link DropBox'" << endl;
        }       
        
    } else {
        
        // unlink button
        if(dropBox->isAuthenticated) {
           img.clear();
           imageLoaded = false;
           dropBox->downloadsComplete = false;
           dropBox->uploadsComplete = false;
           dropBox->unlinkAccount(); 
        } else {
            cout << "Dropbox not authorised. Press '1. Link DropBox'" << endl;
        }
    }
}

//--------------------------------------------------------------
void testApp::touchDoubleTap(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void testApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void testApp::lostFocus(){

}

//--------------------------------------------------------------
void testApp::gotFocus(){

}

//--------------------------------------------------------------
void testApp::gotMemoryWarning(){

}

//--------------------------------------------------------------
void testApp::deviceOrientationChanged(int newOrientation){

}
