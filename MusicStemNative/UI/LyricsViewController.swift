import UIKit

/// A beautiful UIKit view controller for displaying, scrolling, and editing synced lyrics.
class LyricsViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let glassHeaderView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let emptyStateLabel = UILabel()
    
    // MARK: - Properties
    
    private let lyricsManager = LyricsSyncManager()
    private var lyricsData: LyricsSyncManager.LyricsData?
    private var activeLineIndex: Int = -1
    
    /// Delegate callback when user selects a lyric timestamp to seek playback
    var onSeekToTime: ((TimeInterval) -> Void)?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Lyrics"
        view.backgroundColor = .systemBackground
        
        setupNavigationBar()
        setupHeaderView()
        setupTableView()
        setupEmptyState()
        setupConstraints()
        
        loadMockLyrics() // Fallback to showcase UI nicely
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "pencil.circle"),
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        )
    }
    
    private func setupHeaderView() {
        glassHeaderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(glassHeaderView)
        
        titleLabel.text = "Song Title"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        glassHeaderView.contentView.addSubview(titleLabel)
        
        artistLabel.text = "Artist Name"
        artistLabel.font = .systemFont(ofSize: 14, weight: .regular)
        artistLabel.textColor = .secondaryLabel
        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        glassHeaderView.contentView.addSubview(artistLabel)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.register(LyricCell.self, forCellReuseIdentifier: LyricCell.identifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
    }
    
    private func setupEmptyState() {
        emptyStateLabel.text = "No lyrics loaded.\nTap Edit to write or import."
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.font = .systemFont(ofSize: 16, weight: .medium)
        emptyStateLabel.isHidden = true
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            glassHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            glassHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            glassHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            glassHeaderView.heightAnchor.constraint(equalToConstant: 72),
            
            titleLabel.topAnchor.constraint(equalTo: glassHeaderView.contentView.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: glassHeaderView.contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: glassHeaderView.contentView.trailingAnchor, constant: -20),
            
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            artistLabel.leadingAnchor.constraint(equalTo: glassHeaderView.contentView.leadingAnchor, constant: 20),
            artistLabel.trailingAnchor.constraint(equalTo: glassHeaderView.contentView.trailingAnchor, constant: -20),
            
            tableView.topAnchor.constraint(equalTo: glassHeaderView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Public API
    
    /// Load lyrics from URL
    func loadLyrics(from url: URL) {
        do {
            try lyricsManager.loadLyrics(from: url)
            self.lyricsData = lyricsManager.getAllLyrics()
            
            titleLabel.text = lyricsData?.title
            artistLabel.text = lyricsData?.artist
            emptyStateLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
            
            setupSyncCallbacks()
        } catch {
            print("❌ Error loading lyrics: \(error.localizedDescription)")
            showEmptyState()
        }
    }
    
    /// Update playback time to scroll lyrics automatically
    func updatePlaybackTime(_ time: TimeInterval) {
        lyricsManager.updateCurrentLyric(currentTime: time)
    }
    
    // MARK: - Private Methods
    
    private func setupSyncCallbacks() {
        lyricsManager.onLyricChanged = { [weak self] line, index in
            guard let self = self else { return }
            self.activeLineIndex = index
            self.tableView.reloadData()
            
            // Auto scroll to active lyric line in the center of the list
            let indexPath = IndexPath(row: index, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }
    }
    
    private func loadMockLyrics() {
        let mockLines = [
            (0.0, "I hear the drums echoing tonight", 4.0),
            (4.0, "But she hears only whispers of some quiet conversation", 5.0),
            (9.0, "She's coming in, 12:30 flight", 4.0),
            (13.0, "The moonlit wings reflect the stars that guide me towards salvation", 6.0),
            (19.0, "I stopped an old man along the way", 4.0),
            (23.0, "Hoping to find some old forgotten words or ancient melodies", 6.0),
            (29.0, "He turned to me as if to say, 'Hurry boy, it's waiting there for you'", 7.0),
            (36.0, "It's gonna take a lot to drag me away from you", 5.0),
            (41.0, "There's nothing that a hundred men or more could ever do", 5.0),
            (46.0, "I bless the rains down in Africa", 4.0),
            (50.0, "Gonna take some time to do the things we never had", 5.0)
        ]
        
        let mockData = LyricsSyncManager.createLyrics(
            title: "Africa",
            artist: "Toto",
            duration: 280.0,
            lines: mockLines
        )
        
        self.lyricsData = mockData
        titleLabel.text = mockData.title
        artistLabel.text = mockData.artist
        
        // Feed mock data to manager using a temporary file
        do {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("mock_lyrics.json")
            let data = try JSONEncoder().encode(mockData)
            try data.write(to: tempURL)
            loadLyrics(from: tempURL)
        } catch {
            print("Failed to setup mock lyrics: \(error)")
        }
    }
    
    private func showEmptyState() {
        lyricsData = nil
        titleLabel.text = "—"
        artistLabel.text = "—"
        emptyStateLabel.isHidden = false
        tableView.isHidden = true
    }
    
    // MARK: - Actions
    
    @objc private func editButtonTapped() {
        let alert = UIAlertController(title: "Edit Lyrics", message: "Enter lyric line and timestamp (seconds)", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Timestamp (e.g. 12.5)"
            textField.keyboardType = .decimalPad
        }
        alert.addTextField { textField in
            textField.placeholder = "Lyric text"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add/Update", style: .default) { [weak self] _ in
            guard let self = self,
                  let timeStr = alert.textFields?[0].text,
                  let time = TimeInterval(timeStr),
                  let text = alert.textFields?[1].text, !text.isEmpty else { return }
            
            self.addNewLyricLine(timestamp: time, text: text)
        })
        
        present(alert, animated: true)
    }
    
    private func addNewLyricLine(timestamp: TimeInterval, text: String) {
        guard var current = lyricsData else { return }
        
        let newLine = LyricsSyncManager.LyricLine(timestamp: timestamp, text: text, duration: 4.0)
        var updatedLines = current.lines
        updatedLines.append(newLine)
        updatedLines.sort { $0.timestamp < $1.timestamp }
        
        let updated = LyricsSyncManager.LyricsData(
            title: current.title,
            artist: current.artist,
            duration: current.duration,
            lines: updatedLines
        )
        
        self.lyricsData = updated
        self.tableView.reloadData()
        
        // Sync manager reload
        do {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("mock_lyrics.json")
            let data = try JSONEncoder().encode(updated)
            try data.write(to: tempURL)
            loadLyrics(from: tempURL)
        } catch {
            print("Error updating lyric: \(error)")
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension LyricsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lyricsData?.lines.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LyricCell.identifier, for: indexPath) as? LyricCell else {
            return UITableViewCell()
        }
        
        if let line = lyricsData?.lines[indexPath.row] {
            let isActive = indexPath.row == activeLineIndex
            cell.configure(with: line.text, isActive: isActive)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let line = lyricsData?.lines[indexPath.row] {
            onSeekToTime?(line.timestamp)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52.0
    }
}

// MARK: - LyricCell

class LyricCell: UITableViewCell {
    
    static let identifier = "LyricCell"
    
    private let lyricLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none
        
        lyricLabel.font = .systemFont(ofSize: 17, weight: .medium)
        lyricLabel.textColor = .secondaryLabel
        lyricLabel.textAlignment = .center
        lyricLabel.numberOfLines = 0
        lyricLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(lyricLabel)
        
        NSLayoutConstraint.activate([
            lyricLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            lyricLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            lyricLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            lyricLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
        ])
    }
    
    func configure(with text: String, isActive: Bool) {
        lyricLabel.text = text
        
        // Highlight active line with prominent color & font size
        UIView.animate(withDuration: 0.25) {
            if isActive {
                self.lyricLabel.textColor = .systemBlue
                self.lyricLabel.font = .systemFont(ofSize: 20, weight: .bold)
                self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            } else {
                self.lyricLabel.textColor = .secondaryLabel
                self.lyricLabel.font = .systemFont(ofSize: 16, weight: .medium)
                self.transform = .identity
            }
        }
    }
}
