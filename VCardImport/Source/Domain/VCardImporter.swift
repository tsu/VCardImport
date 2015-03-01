import Foundation
import AddressBook
import MiniFuture

class VCardImporter {
  typealias OnSourceDownloadCallback = (VCardSource, Request.ProgressBytes) -> Void
  typealias OnSourceCompleteCallback = (VCardSource, RecordDifferences?, ModifiedHeaderStamp?, NSError?) -> Void
  typealias OnCompleteCallback = NSError? -> Void

  private let onSourceDownload: OnSourceDownloadCallback
  private let onSourceComplete: OnSourceCompleteCallback
  private let onComplete: OnCompleteCallback
  private let urlConnection: URLConnectable
  private let callbackQueue: QueueExecution.Queue

  private let executionQueue = QueueExecution.makeSerialQueue("VCardImporter")

  class func builder() -> Builder {
    return Builder()
  }

  private init(
    onSourceDownload: OnSourceDownloadCallback,
    onSourceComplete: OnSourceCompleteCallback,
    onComplete: OnCompleteCallback,
    urlConnection: URLConnectable,
    callbackQueue: QueueExecution.Queue)
  {
    self.onSourceDownload = onSourceDownload
    self.onSourceComplete = onSourceComplete
    self.onComplete = onComplete
    self.urlConnection = urlConnection
    self.callbackQueue = callbackQueue
  }

  func importFrom(sources: [VCardSource]) {
    // The implementation is long and ugly, but I prefer to keep dispatching
    // calls to background jobs and back to the user-specified queue in one
    // place.

    QueueExecution.async(executionQueue) {
      var error: NSError?
      let addressBook: AddressBook! = AddressBook.sharedInstance(error: &error)

      if let err = error {
        QueueExecution.async(self.callbackQueue) { self.onComplete(err) }
        return
      }

      let sourceImports: [(VCardSource, Future<SourceImportResult>)] = sources.map { source in
        (source, self.checkAndDownloadSource(source))
      }

      for (source, sourceImport) in sourceImports {
        let importResult = sourceImport.get()

        var loadedRecords: [ABRecord]
        var modifiedHeaderStamp: ModifiedHeaderStamp?

        switch importResult {
        case .Success(let res):
          switch res() {
          case .Unchanged:
            QueueExecution.async(self.callbackQueue) {
              self.onSourceComplete(source, nil, nil, nil)
            }
            continue
          case .Changed(let records, let stamp):
            loadedRecords = records
            modifiedHeaderStamp = stamp
          }
        case .Failure(let desc):
          QueueExecution.async(self.callbackQueue) {
            self.onSourceComplete(source, nil, nil, Errors.addressBookFailedToLoadVCardSource(desc))
          }
          continue
        }

        let recordDiff = RecordDifferences.resolveBetween(
          oldRecords: addressBook.loadRecords(),
          newRecords: loadedRecords)

        if !recordDiff.additions.isEmpty {
          let isSuccess = addressBook.addRecords(recordDiff.additions, error: &error)
          if !isSuccess {
            QueueExecution.async(self.callbackQueue) { self.onSourceComplete(source, nil, nil, error!) }
            continue
          }
        }

        if !recordDiff.changes.isEmpty {
          let isSuccess = self.changeRecords(recordDiff.changes, error: &error)
          if !isSuccess {
            QueueExecution.async(self.callbackQueue) { self.onSourceComplete(source, nil, nil, error!) }
            continue
          }
        }

        if addressBook.hasUnsavedChanges {
          let isSaved = addressBook.save(error: &error)
          if !isSaved {
            QueueExecution.async(self.callbackQueue) { self.onSourceComplete(source, nil, nil, error!) }
            continue
          }
        }

        NSLog("vCard source %@: %@", source.name, recordDiff.description)
        QueueExecution.async(self.callbackQueue) {
          self.onSourceComplete(source, recordDiff, modifiedHeaderStamp, nil)
        }
      }

      QueueExecution.async(self.callbackQueue) { self.onComplete(nil) }
    }
  }

  private func changeRecords(changeSets: [RecordChangeSet], error: NSErrorPointer) -> Bool {
    for changeSet in changeSets {
      for (property, value) in changeSet.singleValueChanges {
        let isChanged = Records.setValue(value, toSingleValueProperty: property, of: changeSet.record)
        if !isChanged {
          error.memory = Errors.addressBookFailedToChange(property, of: changeSet.record)
          return false
        }
      }

      for (property, changes) in changeSet.multiValueChanges {
        let isChanged = Records.addValues(
          changes,
          toMultiValueProperty: property,
          of: changeSet.record)
        if !isChanged {
          error.memory = Errors.addressBookFailedToChange(property, of: changeSet.record)
          return false
        }
      }

      if let img = changeSet.imageChange {
        let isChanged = Records.setImage(img, of: changeSet.record)
        if !isChanged {
          error.memory = Errors.addressBookFailedToChangeImage(of: changeSet.record)
          return false
        }
      }
    }

    return true
  }

  private func checkAndDownloadSource(source: VCardSource) -> Future<SourceImportResult> {
    NSLog("vCard source %@: checking if remote has changed…", source.name)
    return urlConnection
      .head(
        source.connection.toURL(),
        headers: Config.Net.VCardHTTPHeaders,
        credential: source.connection.toCredential(.ForSession))
      .flatMap { response in
        let newStamp = ModifiedHeaderStamp(headers: response.allHeaderFields)

        if let oldStamp = source.lastImportResult?.modifiedHeaderStamp {
          if oldStamp == newStamp {
            NSLog("vCard source %@: remote is unchanged since last import (\(oldStamp))", source.name)
            return Future.succeeded(.Unchanged)
          }
        }

        NSLog("vCard source %@: remote has changed (\(newStamp)), downloading…", source.name)
        return self.downloadSource(source).map { records in .Changed(records, newStamp) }
      }
  }

  private func downloadSource(source: VCardSource) -> Future<[ABRecord]> {
    let fileURL = Files.tempURL()
    let onProgressCallback: Request.OnProgressCallback = { progressBytes in
      QueueExecution.async(QueueExecution.mainQueue) {
        self.onSourceDownload(source, progressBytes)
      }
    }
    let future = urlConnection
      .download(
        source.connection.toURL(),
        to: fileURL,
        headers: Config.Net.VCardHTTPHeaders,
        credential: source.connection.toCredential(.ForSession),
        onProgress: onProgressCallback)
      .flatMap(loadRecordsFromFile)
    future.onComplete { _ in Files.remove(fileURL) }
    return future
  }

  private func loadRecordsFromFile(fileURL: NSURL) -> Future<[ABRecord]> {
    let vcardData = NSData(contentsOfURL: fileURL)
    if let records = ABPersonCreatePeopleInSourceWithVCardRepresentation(nil, vcardData) {
      let foundRecords: [ABRecord] = records.takeRetainedValue()
      if foundRecords.isEmpty {
        return Future.failed("no contact data found from vCard file")
      } else {
        return Future.succeeded(foundRecords)
      }
    } else {
      return Future.failed("invalid vCard file")
    }
  }

  private enum SourceImportResult {
    case Unchanged
    case Changed([ABRecord], ModifiedHeaderStamp?)
  }

  class Builder {
    private var onSourceDownload: OnSourceDownloadCallback?
    private var onSourceComplete: OnSourceCompleteCallback?
    private var onComplete: OnCompleteCallback?
    private var urlConnection: URLConnectable?
    private var callbackQueue: QueueExecution.Queue?

    func onSourceDownload(callback: OnSourceDownloadCallback) -> Builder {
      self.onSourceDownload = callback
      return self
    }

    func onSourceComplete(callback: OnSourceCompleteCallback) -> Builder {
      self.onSourceComplete = callback
      return self
    }

    func onComplete(callback: OnCompleteCallback) -> Builder {
      self.onComplete = callback
      return self
    }

    func connectWith(urlConnection: URLConnectable) -> Builder {
      self.urlConnection = urlConnection
      return self
    }

    func queueTo(callbackQueue: QueueExecution.Queue) -> Builder {
      self.callbackQueue = callbackQueue
      return self
    }

    func build() -> VCardImporter {
      if self.onSourceDownload == nil ||
        self.onSourceComplete == nil ||
        self.onComplete == nil ||
        self.urlConnection == nil ||
        self.callbackQueue == nil {
        fatalError("all parameters must be given")
      }
      return VCardImporter(
        onSourceDownload: self.onSourceDownload!,
        onSourceComplete: self.onSourceComplete!,
        onComplete: self.onComplete!,
        urlConnection: self.urlConnection!,
        callbackQueue: self.callbackQueue!)
    }
  }
}
