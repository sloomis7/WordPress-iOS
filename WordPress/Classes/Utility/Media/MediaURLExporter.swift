import Foundation
import MobileCoreServices

/// MediaLibrary export handling of URLs.
///
class MediaURLExporter: MediaExporter {

    var maximumImageSize: CGFloat?
    var stripsGeoLocationIfNeeded = false
    var mediaDirectoryType: MediaLibrary.MediaDirectory = .uploads

    /// Enumerable type value for a URLExport, typed according to the resulting export of the file at the URL.
    ///
    public enum URLExport {
        case exportedImage(MediaImageExport)
        case exportedVideo(MediaVideoExport)
        case exportedGIF(MediaGIFExport)
    }

    public enum URLExportError: MediaExportError {
        case invalidFileURL
        case unknownFileUTI

        var description: String {
            switch self {
            default:
                return NSLocalizedString("The media could not be added to the Media Library.", comment: "Message shown when an image or video failed to load while trying to add it to the Media library.")
            }
        }
        func toNSError() -> NSError {
            return NSError(domain: _domain, code: _code, userInfo: [NSLocalizedDescriptionKey: String(describing: self)])
        }
    }

    /// Exports a file of an unknown type, to a new Media URL.
    ///
    /// Expects files conforming to a video, image or GIF uniform type.
    ///
    func exportURL(fileURL: URL, onCompletion: @escaping (URLExport) -> (), onError: @escaping (MediaExportError) -> ()) {
        do {
            guard fileURL.isFileURL else {
                throw URLExportError.invalidFileURL
            }
            guard let typeIdentifier = fileURL.resourceTypeIdentifier as CFString? else {
                throw URLExportError.unknownFileUTI
            }
            if UTTypeEqual(typeIdentifier, kUTTypeGIF) {
                exportGIF(atURL: fileURL, onCompletion: onCompletion, onError: onError)
            } else if UTTypeConformsTo(typeIdentifier, kUTTypeVideo) || UTTypeConformsTo(typeIdentifier, kUTTypeMovie) {
                exportVideo(atURL: fileURL, typeIdentifier: typeIdentifier as String, onCompletion: onCompletion, onError: onError)
            } else if UTTypeConformsTo(typeIdentifier, kUTTypeImage) {
                exportImage(atURL: fileURL, onCompletion: onCompletion, onError: onError)
            } else {
                throw URLExportError.unknownFileUTI
            }
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }

    /// Exports the known image file at the URL, via MediaImageExporter.
    ///
    fileprivate func exportImage(atURL url: URL, onCompletion: @escaping (URLExport) -> (), onError: @escaping (MediaExportError) -> ()) {
        // Pass the export off to the image exporter
        let exporter = MediaImageExporter()
        exporter.maximumImageSize = maximumImageSize
        exporter.stripsGeoLocationIfNeeded = stripsGeoLocationIfNeeded
        exporter.mediaDirectoryType = mediaDirectoryType
        exporter.exportImage(atURL: url,
                             onCompletion: { (imageExport) in
                                onCompletion(URLExport.exportedImage(imageExport))
        },
                             onError: onError)
    }

    /// Exports the known video file at the URL, via MediaVideoExporter.
    ///
    fileprivate func exportVideo(atURL url: URL, typeIdentifier: String, onCompletion: @escaping (URLExport) -> (), onError: @escaping (MediaExportError) -> ()) {
        // Pass the export off to the video exporter.
        let videoExporter = MediaVideoExporter()
        videoExporter.stripsGeoLocationIfNeeded = stripsGeoLocationIfNeeded
        videoExporter.mediaDirectoryType = mediaDirectoryType
        videoExporter.exportFilename = url.lastPathComponent
        videoExporter.exportVideo(atURL: url,
                                  onCompletion: { videoExport in
                                    onCompletion(URLExport.exportedVideo(videoExport))
        },
                                  onError: onError)
    }

    /// Exports the GIF file at the URL to a new Media URL, by simply copying the file.
    ///
    fileprivate func exportGIF(atURL url: URL, onCompletion: @escaping (URLExport) -> (), onError: @escaping (MediaExportError) -> ()) {
        do {
            let fileManager = FileManager.default
            let mediaURL = try MediaLibrary.makeLocalMediaURL(withFilename: url.lastPathComponent,
                                                              fileExtension: "gif",
                                                              type: mediaDirectoryType)
            try fileManager.copyItem(at: url, to: mediaURL)
            onCompletion(URLExport.exportedGIF(MediaGIFExport(url: mediaURL,
                                                              fileSize: mediaURL.resourceFileSize)))
        } catch {
            onError(exporterErrorWith(error: error))
        }
    }
}
