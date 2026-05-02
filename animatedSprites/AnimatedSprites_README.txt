HOW TO IMPORT AND IMPLEMENT ASEPRITE ANIMATIONS

1. Make sure Aseprite Wizard is installed and enabled in plugins and project settings
2. Drag and drop Aseprite files directly into project (there is a designated folder)
3. Click each sprite and repeat these steps:
	- Go to Import tab on the left, next to scene
	- Select from the dropdown Aseprite SpriteFrames
	- Reimport
*** Make sure the path to your Aseprite executable is correct! Otherwise reimports will not work!
4. Wire it up!
	- Add an AnimatedSprite2D node to the scene
	- Inspector -> SpriteFrames -> New SpriteFrames
	- Go to SpriteFrames Editor
	- Add Frames from SpriteSheet
	- Select the intended aseprite file
