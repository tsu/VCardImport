import UIKit

class VCardSourcesDataSource: NSObject, UITableViewDataSource {
  private let vcardSourceStore: VCardSourceStore
  private let cellReuseIdentifier: String

  init(vcardSourceStore: VCardSourceStore, cellReuseIdentifier: String) {
    self.vcardSourceStore = vcardSourceStore
    self.cellReuseIdentifier = cellReuseIdentifier
  }

  var hasVCardSources: Bool {
    return !vcardSourceStore.isEmpty
  }

  var hasEnabledVCardSources: Bool {
    return vcardSourceStore.countEnabled > 0
  }

  var enabledVCardSources: [VCardSource] {
    return vcardSourceStore.filterEnabled
  }

  func setVCardSourceErrorStatus(source: VCardSource, error: ErrorType) {
    setVCardSourceStatus(
      false,
      message: (error as NSError).localizedDescription,
      modifiedHeaderStamp: nil,
      to: source)
  }

  func setVCardSourceChangedStatus(
    source: VCardSource,
    recordDifferences: RecordDifferences,
    modifiedHeaderStamp: ModifiedHeaderStamp?)
  {
    setVCardSourceStatus(
      true,
      message: recordDifferences.description,
      modifiedHeaderStamp: modifiedHeaderStamp,
      to: source)
  }

  func setVCardSourceUnchangedStatus(source: VCardSource) {
    setVCardSourceStatus(
      true,
      message: "vCard is unchanged since last import",
      modifiedHeaderStamp: nil,
      to: source)
  }

  func saveVCardSource(source: VCardSource) {
    vcardSourceStore.update(source)
    vcardSourceStore.save()
  }

  func vCardSourceForRow(row: Int) -> VCardSource {
    return vcardSourceStore[row]
  }

  func rowForVCardSource(source: VCardSource) -> Int? {
    return vcardSourceStore.indexOf(source)
  }

  // MARK: UITableViewDataSource

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return vcardSourceStore.countAll
  }

  func tableView(
    tableView: UITableView,
    cellForRowAtIndexPath indexPath: NSIndexPath)
    -> UITableViewCell
  {
    let cell = tableView.dequeueReusableCellWithIdentifier(
      cellReuseIdentifier, forIndexPath: indexPath) as! VCardSourceCell
    cell.setContents(vcardSourceStore[indexPath.row])
    return cell
  }

  func tableView(
    tableView: UITableView,
    commitEditingStyle editingStyle: UITableViewCellEditingStyle,
    forRowAtIndexPath indexPath: NSIndexPath)
  {
    if (editingStyle == .Delete) {
      removeVCardSource(indexPath.row)
      tableView.beginUpdates()
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:.Fade)
      tableView.endUpdates()
    }
  }

  func tableView(
    tableView: UITableView,
    moveRowAtIndexPath sourceIndexPath: NSIndexPath,
    toIndexPath destinationIndexPath: NSIndexPath)
  {
    vcardSourceStore.move(fromIndex: sourceIndexPath.row, toIndex: destinationIndexPath.row)
    vcardSourceStore.save()
  }

  // MARK: Helpers

  private func setVCardSourceStatus(
    isSuccess: Bool,
    message: String,
    modifiedHeaderStamp: ModifiedHeaderStamp?,
    to source: VCardSource)
  {
    if vcardSourceStore.hasSource(source) {
      let s = source.withLastImportResult(
        isSuccess,
        message: message,
        at: NSDate(),
        modifiedHeaderStamp: modifiedHeaderStamp)
      vcardSourceStore.update(s)
      vcardSourceStore.save()
    }
  }

  private func removeVCardSource(row: Int) {
    vcardSourceStore.remove(row)
    vcardSourceStore.save()
  }
}
