package;

import sys.FileSystem;
import haxe.zip.Reader;
import sys.io.File;
import haxe.Json;
import haxe.Http;

typedef BintrayVersion = {
	name:String,
	created:String,
}

enum UpdateStatus {
    FetchError;
    UpToDate;
    Downloading;
    Downloaded;
}

class Updater {

    final bintrayAPI = 'https://api.bintray.com';
	final bintrayDLURL = 'https://dl.bintray.com';
    
    var user : String;
    var repo: String;

    public var onUpdateError : String -> Void;
    public var onUpdateFinish : Void -> Void;

    public function new(bintrayUser : String, bintrayRepo : String) {
        user = bintrayUser;
        repo = bintrayRepo;
    }

    public function checkDataFile(pkg:String, outputFile:String, curVersion: String, status : UpdateStatus -> Void) {
        // Fetch latest version info from bintray
        var v = getBintrayPackageVersion(pkg);
        if (v == null) {
            status(FetchError);
            return null;
        }

        if (v.name != curVersion) {
            status(Downloading);
        } else {
            status(UpToDate);
            return v;
        }

        // Fetch file path for latest version from bintray
        var filePath = getBintrayPackageFileName(pkg, v.name);
        if (filePath == null) {
            status(FetchError);
            return null;
        }

        // Download latest binary
        var resultBytes = downloadBinary(filePath);
        if (resultBytes == null) {
            status(FetchError);
            return null;
        }

        status(Downloaded);

        File.saveBytes(filePath, resultBytes);

        var fi = sys.io.File.read(filePath);
        var r = new haxe.zip.Reader(fi);
        var f = r.read();
        for (handle in f) {
            var bytes = Reader.unzip(handle);
            File.saveBytes(outputFile, bytes);
        }

        fi.close();

        FileSystem.deleteFile(filePath);
            
        return v;
    }

    function downloadBinary(file: String){
        var url = '$bintrayDLURL/$user/$repo/$file';

        var http = new Http(url);
        var redirectURL:String = null;
        var resultBytes:haxe.io.Bytes;
        http.onStatus = s -> {
            if (s == 302) {
                redirectURL = http.responseHeaders.get("Location");
            }
        }

        http.onBytes = d -> {
            resultBytes = d;
        }
        http.request();

        if (redirectURL != null) {
            http = new Http(redirectURL);
            http.onBytes = d -> {
                resultBytes = d;
            }
            http.request();
        }

        return resultBytes;
    }

    function getBintrayPackageVersion(pkg : String) {
        var http = new haxe.Http('$bintrayAPI/packages/$user/$repo/$pkg/versions/_latest');

        var res : BintrayVersion = null;
        var error = false;
        http.onStatus = s -> {
            if (s != 200) {
                error = true;
            }
        }

        http.onData = function(data:String) {
            res = haxe.Json.parse(data);
        }

        http.request();

        if (error) {
            return null;
        }

        return res;
    }

    function getBintrayPackageFileName(pkg : String, version: String) {
        var http = new Http('$bintrayAPI/packages/$user/$repo/$pkg/versions/$version/files');
        var filePath:String = null;
        http.onData = data -> {
            if (data != null && data.length > 0){
                var blob = Json.parse(data);
                var f = blob[0];
                filePath = f.path;
            }
        }
        http.request();

        return filePath;
    }
}