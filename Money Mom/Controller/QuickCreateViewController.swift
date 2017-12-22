import UIKit
import AVFoundation

protocol QuickRecordDelegate {
    func didAdd(quickRecord: QuickRecord)
}

class QuickCreateViewController: UIViewController {
    let amountTextField: UITextField = {
        let label = UILabel()
        label.text = "金額："
        label.sizeToFit()
        label.textColor = MMColor.black

        var textField = UITextField()
        textField.leftView = label
        textField.leftViewMode = .always
        textField.textColor = MMColor.black
        textField.backgroundColor = MMColor.white
        return textField
    }()

    let tagCollectionView: UICollectionView = {
        return UICollectionView(frame: CGRect.zero, collectionViewLayout: TagCollectionViewFlowLayout())
    }()

    let recordButton: UIButton = {
        let button = UIButton()
        button.setTitle("按住我錄音", for: .normal)
        button.setTitleColor(MMColor.white, for: .normal)
        button.backgroundColor = MMColor.black
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(startRecording), for: .touchDown)
        button.addTarget(self, action: #selector(stopRecording), for: .touchUpInside)
        button.addTarget(self, action: #selector(stopRecording), for: .touchUpOutside)
        return button
    }()

    let documentDirectory: URL? = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first

    lazy var audioRecorder: AVAudioRecorder? = {
        guard let documentDirectory = documentDirectory else {
            return nil
        }

        var audioRecorder =  try! AVAudioRecorder(url: documentDirectory.appendingPathComponent("recording.m4a"), settings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ])

        audioRecorder.delegate = self
        audioRecorder.prepareToRecord()

        return audioRecorder
    }()

    var player: AVAudioPlayer?

    var tags: [String] = []
    var tagTextFieldText = ""
    var startCreatingTags = false
    var invisibleTagCollectionViewButton = UIButton()
    var delegate: QuickRecordDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = MMColor.white

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))

        addSubviews()
    }

    private func addSubviews() {
        view.addSubview(amountTextField)
        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        amountTextField.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        amountTextField.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor).isActive = true
        amountTextField.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor).isActive = true
        amountTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true

        view.addSubview(tagCollectionView)
        tagCollectionView.translatesAutoresizingMaskIntoConstraints = false
        tagCollectionView.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor).isActive = true
        tagCollectionView.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor).isActive = true
        tagCollectionView.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 10).isActive = true
        tagCollectionView.heightAnchor.constraint(equalToConstant: 44 * 3).isActive = true
        tagCollectionView.backgroundColor = MMColor.white
        tagCollectionView.dataSource = self
        tagCollectionView.delegate = self
        tagCollectionView.register(TagCollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(TagCollectionViewCell.self))
        tagCollectionView.register(TagTextFieldCollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(TagTextFieldCollectionViewCell.self))

        view.addSubview(invisibleTagCollectionViewButton)
        invisibleTagCollectionViewButton.translatesAutoresizingMaskIntoConstraints = false
        invisibleTagCollectionViewButton.leftAnchor.constraint(equalTo: tagCollectionView.leftAnchor).isActive = true
        invisibleTagCollectionViewButton.rightAnchor.constraint(equalTo: tagCollectionView.rightAnchor).isActive = true
        invisibleTagCollectionViewButton.topAnchor.constraint(equalTo: tagCollectionView.topAnchor).isActive = true
        invisibleTagCollectionViewButton.bottomAnchor.constraint(equalTo: tagCollectionView.bottomAnchor).isActive = true

        invisibleTagCollectionViewButton.addTarget(self, action: #selector(userWannaCreateTags), for: .touchUpInside)

        view.addSubview(recordButton)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.topAnchor.constraint(equalTo: tagCollectionView.bottomAnchor, constant: 10).isActive = true
        recordButton.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor).isActive = true
        recordButton.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor).isActive = true
        recordButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
}

extension QuickCreateViewController {
    @objc func userWannaCreateTags() {
        invisibleTagCollectionViewButton.isHidden = true
        (tagCollectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? TagTextFieldCollectionViewCell)?.textField.becomeFirstResponder()
        startCreatingTags = true
    }

    @objc func save() {
        let quickRecord = QuickRecord(amount: amountTextField.text ?? "", tags: tags, audioRecording: "recording.m4a")

        delegate?.didAdd(quickRecord: quickRecord)

        navigationController?.popViewController(animated: true)
    }
}

extension QuickCreateViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(TagTextFieldCollectionViewCell.self), for: indexPath) as? TagTextFieldCollectionViewCell else {
                fatalError()
            }

            cell.delegate = self

            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(TagCollectionViewCell.self), for: indexPath) as? TagCollectionViewCell else {
                fatalError()
            }

            cell.label.text = tags[indexPath.row - 1]
            cell.delegate = self

            return cell
        }
    }
}

extension QuickCreateViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if startCreatingTags, cell is TagTextFieldCollectionViewCell {
            (cell as? TagTextFieldCollectionViewCell)?.textField.becomeFirstResponder()
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.row == 0 {
            let cell = TagTextFieldCollectionViewCell()
            cell.textField.text = tagTextFieldText
            cell.textField.sizeToFit()

            return CGSize(width: min(cell.textField.frame.width + cell.layoutMargins.left + cell.layoutMargins.right, tagCollectionView.frame.width / 2), height: 50)
        } else {
            let cell = TagCollectionViewCell()
            cell.label.text = tags[indexPath.row - 1]
            cell.label.sizeToFit()

            return CGSize(width: min(cell.label.frame.width + cell.button.frame.width + cell.layoutMargins.right + cell.layoutMargins.left, tagCollectionView.frame.width / 2), height: 50);
        }
    }
}

extension QuickCreateViewController: TagTextFieldDelegate {
    func didAdd(tag: String) {
        tags.insert(tag, at: 0)
        tagCollectionView.reloadData()
    }

    func didChange(text: String) {
        tagTextFieldText = text
        tagCollectionView.collectionViewLayout.invalidateLayout()
    }

    func didEndEditing() {
        invisibleTagCollectionViewButton.isHidden = false
    }
}

extension QuickCreateViewController: TagCollectionViewCellDelegate {
    func didTouchButton(in tag: TagCollectionViewCell) {
        tags = tags.filter { $0 != tag.label.text }
        tagCollectionView.reloadData()
    }
}

extension QuickCreateViewController: AVAudioRecorderDelegate {
    @objc func startRecording() {
        let session = AVAudioSession.sharedInstance()

        session.requestRecordPermission { allowed in
            if allowed {
                do {
                    try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
                    try session.setActive(true)
                } catch {
                    fatalError("failed to start recording")
                }

                self.audioRecorder?.record()
                self.recordButton.backgroundColor = MMColor.red
                self.recordButton.setTitleColor(MMColor.white, for: .normal)
                self.recordButton.setTitle("放開結束錄音", for: .normal)
            }
        }
    }

    @objc func stopRecording() {
        audioRecorder?.stop()
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            recordButton.backgroundColor = MMColor.black
            recordButton.setTitleColor(MMColor.white, for: .normal)
            recordButton.setTitle("按住我錄音", for: .normal)

            guard let documentDirectory = documentDirectory else {
                return
            }

            do {
                player = try AVAudioPlayer(contentsOf: documentDirectory.appendingPathComponent("recording.m4a"))
                player?.prepareToPlay()
                player?.play()
            } catch {
                fatalError("Cannot play audio")
            }
        }
    }
}
