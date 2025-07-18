import SpriteKit

class PauseMenuNode: SKNode {
    
    private var sfxToggle: SKLabelNode!
    private var hapticsToggle: SKLabelNode!
    
    override init() {
        super.init()
        setupMenu()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupMenu()
    }

    private func setupMenu() {
        // Dark overlay
        let overlay = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.5), size: UIScreen.main.bounds.size)
        overlay.position = CGPoint.zero
        overlay.zPosition = 99
        overlay.name = "pauseOverlay"
        overlay.alpha = 0.5
        addChild(overlay)

        // Pause menu background using your image
        let background = SKSpriteNode(imageNamed: "paused")
        background.zPosition = 100
        background.name = "pauseBackground"
        background.position = CGPoint.zero
        background.setScale(0.18)
        addChild(background)

        // Resume Button
        let resumeButton = SKLabelNode(text: "Resume")
        resumeButton.fontName = "LuckiestGuy-Regular"
        resumeButton.fontSize = 30
        resumeButton.fontColor = .white
        resumeButton.position = CGPoint(x: 0, y: -10)
        resumeButton.name = "resumeButton"
        resumeButton.zPosition = 101
        addChild(resumeButton)

        // SFX Toggle
        sfxToggle = SKLabelNode(fontNamed: "LuckiestGuy-Regular")
        sfxToggle.fontSize = 26
        sfxToggle.fontColor = .white
        updateSFXLabel()
        addToggle(label: sfxToggle, position: CGPoint(x: 80, y: 40), name: "sfxToggle")

        // Haptics Toggle
        hapticsToggle = SKLabelNode(fontNamed: "LuckiestGuy-Regular")
        hapticsToggle.fontSize = 26
        hapticsToggle.fontColor = .white
        updateHapticsLabel()
        addToggle(label: hapticsToggle, position: CGPoint(x: 80, y: -40), name: "hapticsToggle")
    }

    func toggleSetting(named name: String) {
        let current = UserDefaults.standard.bool(forKey: name)
        UserDefaults.standard.set(!current, forKey: name)

        if name == "soundEffectsEnabled" {
            updateSFXLabel()
        } else if name == "hapticsEnabled" {
            updateHapticsLabel()
        }
    }

    private func updateSFXLabel() {
        let isEnabled = UserDefaults.standard.bool(forKey: "soundEffectsEnabled")
        sfxToggle.text = "\(isEnabled ? "ON" : "OFF")"
    }

    private func updateHapticsLabel() {
        let isEnabled = UserDefaults.standard.bool(forKey: "hapticsEnabled")
        hapticsToggle.text = "\(isEnabled ? "ON" : "OFF")"
    }
    
    private func addToggle(label: SKLabelNode, position: CGPoint, name: String) {
        label.position = position
        label.name = name
        label.zPosition = 101
        addChild(label)

        let hitbox = SKSpriteNode(color: .clear, size: CGSize(width: 200, height: 40))
        hitbox.position = position
        hitbox.name = name
        hitbox.zPosition = 100  // Slightly below the label
        addChild(hitbox)
    }

}
