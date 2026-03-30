import UIKit

class ViewController: UIViewController {
    
    private let timeLabel = UILabel()
    private let lockStatusLabel = UILabel()
    private var timer: Timer?
    private var seconds = 0
    private let pwdKey = "kidsLockPwd"
    private var isLocked = false
    
    private var currentPwd: String {
        UserDefaults.standard.string(forKey: pwdKey) ?? "666"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        timeLabel.text = "00:00"
        timeLabel.font = .systemFont(ofSize: 60, weight: .bold)
        timeLabel.textColor = .systemBlue
        timeLabel.textAlignment = .center
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timeLabel)
        
        lockStatusLabel.text = "未锁定"
        lockStatusLabel.font = .systemFont(ofSize: 16)
        lockStatusLabel.textColor = .systemGreen
        lockStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lockStatusLabel)
        
        let setBtn = createButton(title: "设置时间", color: .systemBlue, action: #selector(showTimePicker))
        let startBtn = createButton(title: "开始锁定", color: .systemRed, action: #selector(startLock))
        let pwdBtn = createButton(title: "修改密码", color: .systemGray, action: #selector(changePwd))
        
        let stack = UIStackView(arrangedSubviews: [timeLabel, lockStatusLabel, setBtn, startBtn, pwdBtn])
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            setBtn.widthAnchor.constraint(equalToConstant: 220),
            setBtn.heightAnchor.constraint(equalToConstant: 50),
            startBtn.widthAnchor.constraint(equalToConstant: 220),
            startBtn.heightAnchor.constraint(equalToConstant: 50),
            pwdBtn.widthAnchor.constraint(equalToConstant: 220),
            pwdBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func createButton(title: String, color: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    @objc private func showTimePicker() {
        let alert = UIAlertController(title: "选择时长", message: nil, preferredStyle: .actionSheet)
        [10, 20, 30, 45, 60].forEach { min in
            alert.addAction(.init(title: "\(min)分钟", style: .default, handler: { _ in
                self.seconds = min * 60
                self.updateTime()
            }))
        }
        alert.addAction(.init(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func startLock() {
        guard !isLocked else { return }
        guard seconds > 0 else {
            showAlert(title: "提示", message: "请先设置时间")
            return
        }
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.seconds > 0 {
                self.seconds -= 1
                self.updateTime()
            }
            if self.seconds <= 0 {
                self.timer?.invalidate()
                self.showLockView()
            }
        }
        
        isLocked = true
        lockStatusLabel.text = "🔒 锁定中"
        lockStatusLabel.textColor = .systemRed
    }
    
    private func showLockView() {
        DispatchQueue.main.async { [weak self] in
            self?.presentLockAlert()
        }
    }
    
    private func presentLockAlert(incorrectAttempts: Int = 0) {
        let alert = UIAlertController(
            title: "🔒 时间已到",
            message: incorrectAttempts > 0 ? "密码错误，还剩\(3 - incorrectAttempts)次机会" : "输入密码解锁",
            preferredStyle: .alert
        )
        
        alert.addTextField { $0.isSecureTextEntry = true; $0.placeholder = "密码" }
        alert.addAction(.init(title: "解锁", style: .default, handler: { [weak self] _ in
            guard let self = self,
                  let pwd = alert.textFields?[0].text,
                  pwd == self.currentPwd else {
                let newAttempts = incorrectAttempts + 1
                if newAttempts < 3 {
                    self?.presentLockAlert(incorrectAttempts: newAttempts)
                } else {
                    self?.showAlert(title: "错误", message: "密码错误次数过多")
                }
                return
            }
            self.unlock()
        }))
        alert.addAction(.init(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func unlock() {
        isLocked = false
        seconds = 0
        updateTime()
        lockStatusLabel.text = "✅ 未锁定"
        lockStatusLabel.textColor = .systemGreen
        showAlert(title: "解锁成功", message: "你可以继续使用")
    }
    
    @objc private func changePwd() {
        let alert = UIAlertController(title: "修改密码", message: "仅数字", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "原密码"; $0.isSecureTextEntry = true }
        alert.addTextField { $0.placeholder = "新密码4-6位"; $0.isSecureTextEntry = true }
        alert.addAction(.init(title: "确定", style: .default, handler: { [weak self] _ in
            guard let self = self,
                  let old = alert.textFields?[0].text, old == self.currentPwd,
                  let new = alert.textFields?[1].text, (4...6).contains(new.count), Int(new) != nil else {
                self?.showAlert(title: "错误", message: "原密码错误或新密码格式不正确")
                return
            }
            UserDefaults.standard.set(new, forKey: self.pwdKey)
            self.showAlert(title: "成功", message: "密码已修改")
        }))
        alert.addAction(.init(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    private func updateTime() {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        timeLabel.text = String(format: "%02d:%02d", minutes, remainingSeconds)
        timeLabel.textColor = seconds <= 10 && seconds > 0 ? .systemRed : .systemBlue
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
