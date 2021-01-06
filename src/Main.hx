package;

import Updater.UpdateStatus;
import h2d.Tile;
import h2d.Bitmap;
import h2d.Interactive;
import sys.io.Process;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;
import sys.thread.Thread;
import hxd.res.DefaultFont;
import h2d.Text;

typedef ThreadMsg = {
	type:String,
	data:Dynamic,
}

typedef ManifestPkgVersion = {
	?version:String,
	?created:String,
}

typedef Manifest = {
	?game:ManifestPkgVersion,
	?launcher:ManifestPkgVersion,
}

class Main extends hxd.App {
	// Your bintray username
	static final bintrayUser = "jefvel";
	// The bintray repo to look in
	static final bintrayRepo = "karanten";

	// The bintray package to look for
	// Versions should contain one file,
	// which is a zip containing the compiled game data file
	static final gamePackage = "data";
	// The local game file will be called this
    static final gameFile = "game.dat";

    // Launcher package
    static final launcherPackage = "launcher-data";
    // Launcher file
    static final launcherFile = "hlboot.dat";

	// set this to either "hl", or "./hl" or "./yourgame" or whatever you named the hashlink executable
	static var hashlinkExecutable = "hl";

	// Local manifest info file
    static final manifestFile = "manifest.json";

	var infoText:Text;
	var localManifest:Manifest;

	var gameReady = false;

	var mainThread:Thread;

	var releaseDateText:Text;

	var launchButton:Interactive;
	var windowPadding = 20;
	var bg:Bitmap;

	var changelogBtn:Interactive;

	var updater:Updater;

	public override function init() {
		initResources();

		updater = new Updater(bintrayUser, bintrayRepo);

		bg = new Bitmap(hxd.Res.bg.toTile(), s2d);

		hashlinkExecutable = Sys.executablePath();

		infoText = new Text(DefaultFont.get(), s2d);
		infoText.textColor = 0xFFFFFF;

		mainThread = Thread.current();

        loadLocalManifest();
		downloadFun();

		releaseDateText = new Text(DefaultFont.get(), s2d);
		releaseDateText.textColor = 0xFFFFFF;
		releaseDateText.textAlign = Right;

		var launchText = new Text(DefaultFont.get());
		launchText.text = "PLAY";
		var px = 25;
		var py = 12;

		launchText.x = px;
		launchText.y = py;

		launchButton = new Interactive(launchText.textWidth + px * 2, launchText.textHeight + py * 2, s2d);
		launchButton.addChild(launchText);
		launchButton.backgroundColor = 0xff05040c;

		launchButton.onClick = e -> {
			launchGame();
		}

		engine.backgroundColor = 0x333333;
		bm = new Bitmap(Tile.fromColor(0xFFffFF, 8, 8), s2d);
		title = new Text(hxd.Res.futilepro_medium_12.toFont(), s2d);
		title.x = windowPadding;
		title.y = windowPadding - 4;
		title.textColor = 0xFFFFFF;
		title.text = "Karantän";
        title.scale(2.0);
        
		var changelogText = new Text(DefaultFont.get());
		changelogText.text = "Changelog";
		var px = 5;
		var py = 2;

		changelogText.x = px;
		changelogText.y = py;

		changelogBtn = new Interactive(changelogText.textWidth + px * 2, changelogText.textHeight + py * 2, s2d);
		changelogBtn.addChild(changelogText);

		changelogBtn.onClick = e -> {}

        onResize();
	}

	override function onResize() {
		var pixelSize = 2;
		var s = hxd.Window.getInstance();

		var scale = 1.0;

		var w = Std.int(s.width / (pixelSize * scale));
		if (w <= 1)
			w = 1;
		var h = Std.int(s.height / (pixelSize * scale));
		if (h <= 1)
			h = 1;

		s2d.scaleMode = ScaleMode.Stretch(w, h);
	}

	var title:Text;

	var bm:Bitmap;

	function loadLocalManifest() {
		localManifest = {};

		if (FileSystem.exists(manifestFile)) {
			var mstring = File.getContent(manifestFile);
			try {
				localManifest = Json.parse(mstring);
			} catch (e) {}
		}

		if (localManifest.game == null) {
			localManifest.game = {};
		}
		if (localManifest.launcher == null) {
			localManifest.launcher = {};
		}
    }
    
    function saveManifest(m: Manifest){
        localManifest = m;
        File.saveContent(manifestFile, Json.stringify(localManifest));
    }

	var time = 0.0;

	override function update(dt:Float) {
		super.update(dt);
		time += dt;

		var msg:ThreadMsg = Thread.readMessage(false);
		if (msg != null) {
			if (msg.type == "log") {
				log(msg.data);
			}
			if (msg.type == "gameReady") {
                gameReady = true;
                saveManifest(msg.data);
            }
            if (msg.type == "restartLauncher") {
                saveManifest(msg.data);
                restartLauncher();
            }
		}

		infoText.x = infoText.y = windowPadding;

		if (localManifest != null && localManifest.game != null) {
			var gm = localManifest.game;
			if (gm.created != null) {
				var d = Date.fromString(gm.created.substr(0, 10));
				var formattedDate = DateTools.format(d, "%Y-%m-%d");

				releaseDateText.text = 'v.${gm.version}\n${formattedDate}';
				releaseDateText.x = s2d.width - windowPadding;
				releaseDateText.y = windowPadding;
			}
		}

		if (gameReady) {
			launchButton.alpha += dt / 0.2;
		} else {
			launchButton.alpha = 0.5;
		}

		launchButton.x = Math.round((s2d.width - windowPadding - launchButton.width));
		launchButton.y = Math.round(s2d.height - windowPadding - launchButton.height);

		bm.x = windowPadding + Math.cos(time * 8.0) * 8;
		bm.y = s2d.height - windowPadding;

		infoText.y = title.y + title.textHeight * title.scaleY - 3;

		if (gameReady) {
			bm.alpha -= dt / 0.4;
		}

		changelogBtn.x = windowPadding;
		changelogBtn.y = s2d.height - changelogBtn.height - windowPadding - 10;
	}

	function log(msg:String) {
		infoText.text = '$msg';
	}

	function sendGameReady(manifest:Manifest) {
		mainThread.sendMessage({
			type: "gameReady",
			data: manifest,
		});
	}

	function downloadFun() {
		Thread.create(() -> {
			function log(msg) {
				mainThread.sendMessage({
					type: "log",
					data: msg,
				});
            }

            var m:Manifest = {};

            #if !debug
            function launcherInfoMessages(l:UpdateStatus) {
                log(switch(l) {
                    case FetchError: "Couldn't get launcher info";
                    case UpToDate: "Launcher is up to date";
                    case Downloading: "Downloading new launcher";
                    case Downloaded: "Launcher downloaded";
                });
            }

            var launcherInfo = updater.checkDataFile(launcherPackage, launcherFile, localManifest.launcher.version, launcherInfoMessages);
            if (m == null) {
                return;
            }

            m.launcher = {
                version: launcherInfo.name,
                created: launcherInfo.created,
            }

            // Launcher was updated, restart it
            if (localManifest.launcher.version != m.launcher.version) {
                log("Launcher updated. Restarting...");
                mainThread.sendMessage({
                    type: "restartLauncher",
                    data: m,
                });
                return;
            }
            #end

            function gameInfoMessages(l:UpdateStatus) {
                log(switch(l) {
                    case FetchError: "Couldn't get game version";
                    case UpToDate: "Game is up to date";
                    case Downloading: "Downloading updates...";
                    case Downloaded: "Updates downloaded";
                });
            }

            var gameInfo = updater.checkDataFile(gamePackage, gameFile, localManifest.game.version, gameInfoMessages);
            if (gameInfo == null) {
                return;
            }

			m.game = {
				version: gameInfo.name,
				created: gameInfo.created,
            };

            log("Game is ready");

			sendGameReady(m);
		});
	}

	function launchGame() {
		if (!gameReady) {
			return;
		}

        new Process(hashlinkExecutable, [gameFile, '--savedir=${Sys.getCwd()}'], true);

        Sys.sleep(0.1);
		Sys.exit(0);
    }
    
    function restartLauncher() {
        new Process(hashlinkExecutable, Sys.args(), true);
        Sys.exit(0);
    }

	function initResources() {
		#if (debug && hl)
		hxd.Res.initLocal();
		hxd.res.Resource.LIVE_UPDATE = true;
		#else
		hxd.Res.initEmbed();
		#end
	}

	static function main() {
		#if (!debug && hl)
		hl.UI.closeConsole();
		#end

		new Main();
	}
}
