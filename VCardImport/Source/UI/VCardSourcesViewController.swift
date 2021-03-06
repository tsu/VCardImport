import UIKit

private let CellIdentifier = "VCardSourceCell"
private let ToolbarHeight: CGFloat = 52
private let AddGuideLabelHorizontalMargin: CGFloat = 25

class VCardSourcesViewController: UIViewController, UITableViewDelegate {
  private let dataSource: VCardSourcesDataSource
  private let urlDownloadFactory: URLDownloadFactory

  private var toolbar: VCardToolbar!
  private var tableView: UITableView!
  private var editButton: UIBarButtonItem!
  private var addButton: UIBarButtonItem!
  private var addGuideLabel: UILabel!
  private var importProgress: ImportProgress?

  init(appContext: AppContext) {
    dataSource = VCardSourcesDataSource(
      vcardSourceStore: appContext.vcardSourceStore,
      cellReuseIdentifier: CellIdentifier)
    urlDownloadFactory = appContext.urlDownloadFactory

    super.init(nibName: nil, bundle: nil)

    editButton = editButtonItem()
    navigationItem.leftBarButtonItem = editButton

    addButton = UIBarButtonItem(
      barButtonSystemItem: .Add,
      target: self,
      action: #selector(VCardSourcesViewController.addVCardSource(_:)))
    navigationItem.rightBarButtonItem = addButton

    navigationItem.title = Config.Executable
  }

  required init?(coder decoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    func makeToolbar() -> VCardToolbar {
      return VCardToolbar(importHandler: { [unowned self] in self.importVCardSources() })
    }

    func makeTableView() -> UITableView {
      let tv = UITableView(frame: CGRect.zero, style: .Plain)
      tv.estimatedRowHeight = 80
      tv.rowHeight = UITableViewAutomaticDimension
      tv.tableFooterView = UIView(frame: CGRect.zero)
      tv.dataSource = dataSource
      tv.delegate = self
      tv.registerClass(VCardSourceCell.self, forCellReuseIdentifier: CellIdentifier)
      return tv
    }

    func makeAddGuideLabel() -> UILabel {
      let label = UILabel()
      label.text = "Tap + to add a vCard source"
      label.textColor = UIColor.grayColor()
      label.font = UIFont.fontForHeadlineStyle()
      label.textAlignment = .Center
      label.lineBreakMode = .ByWordWrapping
      label.numberOfLines = 0
      return label
    }

    func setupLayout() {
      let viewNamesToObjects = [
        "tableView": tableView,
        "toolbar": toolbar
      ]

      tableView.translatesAutoresizingMaskIntoConstraints = false
      toolbar.translatesAutoresizingMaskIntoConstraints = false

      NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
        "H:|[tableView]|",
        options: [],
        metrics: nil,
        views: viewNamesToObjects))

      NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
        "V:|[tableView]|",
        options: [],
        metrics: nil,
        views: viewNamesToObjects))

      NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
        "H:|[toolbar]|",
        options: [],
        metrics: nil,
        views: viewNamesToObjects))

      NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
        "V:[toolbar(==toolbarHeight)]|",
        options: [],
        metrics: ["toolbarHeight": ToolbarHeight],
        views: viewNamesToObjects))
    }

    toolbar = makeToolbar()
    tableView = makeTableView()
    addGuideLabel = makeAddGuideLabel()

    view = UIView()
    view.addSubview(tableView)
    view.addSubview(toolbar)
    view.addSubview(addGuideLabel)

    setupLayout()
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    refreshSubviewStates()
  }

  override func viewWillLayoutSubviews() {
    func centeredFrameFor(subview: UIView, horizontalMargin: CGFloat) -> CGRect {
      let maxSize = CGSize(
        width: view.bounds.width - horizontalMargin * 2,
        height: view.bounds.height)
      let minSize = subview.sizeThatFits(maxSize)
      return CGRect(
        x: view.bounds.origin.x + view.bounds.width / 2 - minSize.width / 2,
        y: view.bounds.origin.y + view.bounds.height / 2 - minSize.height / 2,
        width: minSize.width,
        height: minSize.height)
    }

    let insets = makeTableContentInsets()
    tableView.contentInset = insets
    tableView.scrollIndicatorInsets = insets

    addGuideLabel.frame = centeredFrameFor(addGuideLabel, horizontalMargin: AddGuideLabelHorizontalMargin)
  }

  // MARK: UITableViewDelegate

  func tableView(
    tableView: UITableView,
    didSelectRowAtIndexPath indexPath: NSIndexPath)
  {
    let oldSource = dataSource.vCardSourceForRow(indexPath.row)
    let vc = VCardSourceDetailViewController(
      source: oldSource,
      isNewSource: false,
      downloadsWith: urlDownloadFactory,
      saveHandler: { [unowned self] newSource in
        self.dataSource.saveVCardSource(newSource)
        self.tableView.beginUpdates()
        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
        self.tableView.endUpdates()
      })
    navigationController!.pushViewController(vc, animated: true)
  }

  func tableView(
    tableView: UITableView,
    didEndEditingRowAtIndexPath indexPath: NSIndexPath)
  {
    refreshSubviewStates()
  }

  // MARK: Actions

  override func setEditing(editing: Bool, animated: Bool) {
    super.setEditing(editing, animated: animated)
    tableView.setEditing(editing, animated: animated)
    if !editing {
      refreshSubviewStates()
    }
  }

  func addVCardSource(sender: AnyObject) {
    let vc = VCardSourceDetailViewController(
      source: VCardSource.empty(),
      isNewSource: true,
      downloadsWith: urlDownloadFactory,
      saveHandler: { [unowned self] newSource in
        self.dataSource.saveVCardSource(newSource)
        self.tableView.reloadData()
      })
    let nc = UINavigationController(rootViewController: vc)
    nc.modalPresentationStyle = .FormSheet
    presentViewController(nc, animated: true, completion: nil)
  }

  func importVCardSources() {
    let sources = dataSource.enabledVCardSources

    beginProgress(sources)
    refreshSubviewStates()

    VCardImportTask(
      downloadsWith: urlDownloadFactory,
      queueTo: QueueExecution.mainQueue,
      sourceCompletionHandler: { source, recordDiff, modifiedHeaderStamp, error in
        if let err = error {
          self.dataSource.setVCardSourceErrorStatus(source, error: err)
        } else if let diff = recordDiff {
          self.dataSource.setVCardSourceChangedStatus(
            source,
            recordDifferences: diff,
            modifiedHeaderStamp: modifiedHeaderStamp)
        } else {
          self.dataSource.setVCardSourceUnchangedStatus(source)
        }
        self.inProgress(.Complete, forSource: source)
        self.reloadTableViewSourceRow(source)
      },
      completionHandler: { error in
        if let err = error {
          self.presentAlertForError(err)
        }
        self.endProgress()
        self.refreshSubviewStates()
      },
      onSourceDownloadProgress: { source, progress in
        let ratio = progress.totalBytesExpected > 0
          ? Float(progress.totalBytes) / Float(progress.totalBytesExpected)
          : 0.33
        self.inProgress(.Download(completionRatio: ratio), forSource: source)
      },
      onSourceResolveRecordsProgress: { source, progress in
        let ratio = Float(progress.totalPhasesCompleted) / Float(progress.totalPhasesToComplete)
        self.inProgress(.ResolveRecords(completionRatio: ratio), forSource: source)
      },
      onSourceApplyRecordsProgress: { source, progress in
        let ratio = Float(progress.totalAdded + progress.totalChanged) / Float(progress.totalToApply)
        self.inProgress(.ApplyRecords(completionRatio: ratio), forSource: source)
    }).importFrom(sources)
  }

  // MARK: Helpers

  private func refreshSubviewStates() {
    addButton.enabled = !editing

    editButton.enabled = dataSource.hasVCardSources

    toolbar.importButtonEnabled =
      !editing &&
      importProgress == nil &&
      dataSource.hasEnabledVCardSources

    addGuideLabel.hidden = dataSource.hasVCardSources
  }

  private func reloadTableViewSourceRow(source: VCardSource) {
    if let row = dataSource.rowForVCardSource(source) {
      let indexPath = NSIndexPath(forRow: row, inSection: 0)
      tableView.beginUpdates()
      tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
      tableView.endUpdates()
    }
  }

  private func presentAlertForError(error: ErrorType) {
    let alertController = UIAlertController(
      title: (error as NSError).localizedFailureReason ?? "Failure",
      message: (error as NSError).localizedDescription,
      preferredStyle: .Alert)
    let dismissAction = UIAlertAction(title: "OK", style: .Default, handler: nil)

    alertController.addAction(dismissAction)

    presentViewController(alertController, animated: true, completion: nil)
  }

  private func makeTableContentInsets() -> UIEdgeInsets {
    return UIEdgeInsets(
      top: topLayoutGuide.length,
      left: 0,
      bottom: bottomLayoutGuide.length + ToolbarHeight,
      right: 0)
  }

  private func beginProgress(sources: [VCardSource]) {
    importProgress = ImportProgress(sourceIds: sources.map { $0.id })
    toolbar.beginProgress("Checking for changes…")
  }

  private func inProgress(
    type: ImportProgress.Progress,
    forSource source: VCardSource)
  {
    let progress = importProgress!.inProgress(type, forId: source.id)
    let text = type.describeProgress(source.name)
    NSLog("Import progress %0.1f%%: %@", progress * 100, text)
    toolbar.inProgress(text: text, progress: progress)
  }

  private func endProgress() {
    importProgress = nil
    toolbar.endProgress()
  }
}
