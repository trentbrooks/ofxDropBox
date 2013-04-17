#include "ofMain.h"
#include "testApp.h"

int main(){
	
    
    // normal
    ofAppiPhoneWindow * iOSWindow = new ofAppiPhoneWindow();	
	//iOSWindow->enableDepthBuffer();
	//iOSWindow->enableAntiAliasing(4);	
	//iOSWindow->enableRetinaSupport();	
	ofSetupOpenGL(iOSWindow, 480, 320, OF_FULLSCREEN);
	ofRunApp(new testApp);
    
    
    // native
    /*ofAppiPhoneWindow *window = new ofAppiPhoneWindow();
    ofSetupOpenGL(ofPtr<ofAppBaseWindow>(window), 1024,768, OF_FULLSCREEN);
    window->enableRetinaSupport(); 
    window->startAppWithDelegate("DBAppDelegate");*/
}
