#pragma once

#include "ofMain.h"
#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"
#include "ofxDropBox.h"

class testApp : public ofxiPhoneApp{
	
    public:
        void setup();
        void update();
        void draw();
        void exit();
	
        void touchDown(ofTouchEventArgs & touch);
        void touchMoved(ofTouchEventArgs & touch);
        void touchUp(ofTouchEventArgs & touch);
        void touchDoubleTap(ofTouchEventArgs & touch);
        void touchCancelled(ofTouchEventArgs & touch);

        void lostFocus();
        void gotFocus();
        void gotMemoryWarning();
        void deviceOrientationChanged(int newOrientation);
    
        // dropbox
        ofxDropBox* dropBox;
        void onDropBoxAuthorised(const void * sender, bool &success);
        void onDropBoxUpload(const void * sender, bool &success);
        void onDropBoxDownload(const void * sender, bool &success);
    
        // downloaded image
        bool imageLoaded;
        ofImage img;
};


