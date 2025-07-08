import UIKit
import AVFoundation

/// Main UI View Controller for Performance Tests
class MainUIViewController: UIViewController {
    
    // MARK: - Constants
    
    private struct Constants {
        static let spacing: CGFloat = 20
        static let cellIdentifier = "TestCell"
    }
    
    // MARK: - Properties
    
    private let backgroundTaskManager = BackgroundTaskManager()
    private let backgroundTaskSwitch = UISwitch()
    private let tableView = UITableView()
    private var testRecords: [Any] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBackgroundTask()
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        backgroundTaskManager.cleanup()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Performance Tests"
        
        setupBackgroundTaskControls()
        setupTableView()
        setupConstraints()
    }
    
    private func setupBackgroundTaskControls() {
        let backgroundLabel = UILabel()
        backgroundLabel.text = "Keep running in background"
        backgroundLabel.font = .systemFont(ofSize: 16)
        backgroundLabel.translatesAutoresizingMaskIntoConstraints = false
        
        backgroundTaskSwitch.isOn = true
        backgroundTaskSwitch.addTarget(self, action: #selector(backgroundTaskSwitchChanged), for: .valueChanged)
        backgroundTaskSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(backgroundLabel)
        view.addSubview(backgroundTaskSwitch)
        
        NSLayoutConstraint.activate([
            backgroundLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.spacing),
            backgroundLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.spacing),
            backgroundTaskSwitch.centerYAnchor.constraint(equalTo: backgroundLabel.centerYAnchor),
            backgroundTaskSwitch.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.spacing)
        ])
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: backgroundTaskSwitch.bottomAnchor, constant: Constants.spacing),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupBackgroundTask() {
        backgroundTaskManager.configure()
    }
    
    private func setupNotifications() {
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    // MARK: - Actions
    
    @objc private func backgroundTaskSwitchChanged() {
        backgroundTaskManager.setEnabled(backgroundTaskSwitch.isOn)
    }
    
    @objc private func appDidEnterBackground() {
        print("App entered background")
        backgroundTaskManager.startBackgroundExecution()
    }
    
    @objc private func appWillEnterForeground() {
        print("App will enter foreground")
        backgroundTaskManager.stopBackgroundExecution()
    }
    
    // MARK: - Navigation
    
    private func navigateToTest(at index: Int) {
        let testItem = testItems[index]
        let viewController = testItem.viewControllerClass.init()
        
        // Configure test records if needed
        if testItem.needsTestRecords {
            configureTestRecords(for: viewController)
        }
        
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func configureTestRecords(for viewController: UIViewController) {
        if let openGLVC = viewController as? OpenGLUIViewController {
            openGLVC.testRecords = testRecords as? NSMutableArray
        } else if let metalVC = viewController as? MetalUIViewController {
            metalVC.testRecords = testRecords as? NSMutableArray
        }
    }
}

// MARK: - UITableViewDataSource

extension MainUIViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return testItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath)
        let testItem = testItems[indexPath.row]
        
        cell.textLabel?.text = testItem.title
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MainUIViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        navigateToTest(at: indexPath.row)
    }
} 