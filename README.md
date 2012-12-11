![https://github.com/trentbrooks/ofxDropBox/raw/master/screenshot.jpg](https://github.com/trentbrooks/ofxDropBox/raw/master/screenshot.jpg)
## ofxDropBox ##
Openframeworks/ios addon (tested with OF 0073, Xcode 4.3.1, ios 5.1) for the DropBox sdk- https://www.dropbox.com/developers/reference/sdk.

Example shows how to upload and download files. All uploads and downloads are queued, so you can add multiple at once. 

## How to setup DropBox SDK in Xcode ##
Original dropbox ios tutorial: https://www.dropbox.com/developers/start/setup#ios

1. create a dropbox app on https://www.dropbox.com/developers/apps
2. download the dropbox sdk: https://www.dropbox.com/developers/reference/sdk
    - once downloaded, drag and drop the 'DropboxSDK.framework' onto your OF xcode project
    - make sure you check the 'copy items into destination group's folder' checkbox.
3. add the 'Security.framework' to your OF xcode project
    - Under TARGETS > ofxDropBoxExample, under the 'Build Phases' tab, where it says 'Link binary with libraries', click '+' and select the 'Security.framework'.
4. copy your dropbox app key + secret from dropbox website
    - ref: https://www.dropbox.com/developers/start/authentication#ios
5. Edit the ofxiphone-info.plist in your OF xcode project (right click open as source code)
    - make sure the UIApplicationExitsOnSuspend is set to false 
    - Add the following code at the top after the first <dict> tag and replace 'db-APP_KEY' with your app key eg. 'db-n0vfoe7o3a5bmtz'.

    // ofxiphone-info.plist
	<key>CFBundleURLTypes</key>
	<array>
	<dict>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>db-APP_KEY</string>
		</array>
	</dict>
	</array>

7. If testing with the ofxDropBoxExample project. Remember to copy 'test.jpg' to your DropBox/Apps/YourApp folder otherwise the download won't work.
6. That should be it. See the example testApp to see how to connect, upload, and download using ofxDropBox.

## Sample usage ##
	// setup
	ofxDropBox* dropBox = new ofxDropBox(); 
	string appKey = "APP_KEY"; 
    string appSecret = "APP_SECRET";
    dropBox->startSession(appKey, appSecret);
    if(!dropBox->isAuthenticated) dropBox->linkAccount();

	// download file from your dropbox to phone
	dropBox->downloadFile("test.jpg"); 
	dropBox->downloadFile("blah.jpg"); 

	// upload from phone data folder to dropbox
	dropBox->uploadFile("Default.png"); 
    dropBox->uploadFile("sample.csv");

See example project for usage.


-Trent Brooks