import SpriteKit

class PauseMenuNode: SKNode {
    
    private var sfxToggle: SKLabelNode!
    private var hapticsToggle: SKLabelNode!
    private var musicToggle: SKLabelNode!
    
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
        let modal = SKSpriteNode(imageNamed: "PausedBackground")
        modal.zPosition = 100
        modal.name = "pauseBackground"
        modal.position = CGPoint.zero
        modal.setScale(0.18)
        addChild(modal)
        
        // Resume Button
        let resumeButton = SKSpriteNode(imageNamed: "ResumeButton")
        resumeButton.name = "resumeButton"
        resumeButton.zPosition = 101
        resumeButton.position = CGPoint(x: -70, y: -90)
        resumeButton.setScale(0.2)
        addChild(resumeButton)
        
        // Quit Button
        let quitButton = SKSpriteNode(imageNamed: "QuitButtonPauseMenu")
        quitButton.name = "quitButton"
        quitButton.zPosition = 101
        quitButton.position = CGPoint(x: 70, y: -90)
        quitButton.setScale(0.2)
        addChild(quitButton)
        
        // Music Toggle
        musicToggle = SKLabelNode(fontNamed: "LuckiestGuy-Regular")
        musicToggle.fontSize = 24
        musicToggle.fontColor = .white
        updateMusicLabel()
        addToggle(label: musicToggle, position: CGPoint(x: 80, y: 45), name: "musicToggle")
        
        // Music Toggle Background (positioned after text to center on it)
        let musicToggleBackground = SKSpriteNode(color: SKColor.brown.withAlphaComponent(0.8), size: CGSize(width: 80, height: 40))
        musicToggleBackground.position = CGPoint(x: musicToggle.position.x, y: musicToggle.position.y + musicToggle.frame.height/4)
        musicToggleBackground.zPosition = 100
        musicToggleBackground.name = "musicToggleBackground"
        addChild(musicToggleBackground)
        
        // SFX Toggle
        sfxToggle = SKLabelNode(fontNamed: "LuckiestGuy-Regular")
        sfxToggle.fontSize = 24
        sfxToggle.fontColor = .white
        updateSFXLabel()
        addToggle(label: sfxToggle, position: CGPoint(x: 80, y: 0), name: "sfxToggle")
        
        // SFX Toggle Background (positioned after text to center on it)
        let sfxToggleBackground = SKSpriteNode(color: SKColor.brown.withAlphaComponent(0.8), size: CGSize(width: 80, height: 40))
        sfxToggleBackground.position = CGPoint(x: sfxToggle.position.x, y: sfxToggle.position.y + sfxToggle.frame.height/4)
        sfxToggleBackground.zPosition = 100
        sfxToggleBackground.name = "sfxToggleBackground"
        addChild(sfxToggleBackground)
        
        // Haptics Toggle
        hapticsToggle = SKLabelNode(fontNamed: "LuckiestGuy-Regular")
        hapticsToggle.fontSize = 24
        hapticsToggle.fontColor = .white
        updateHapticsLabel()
        addToggle(label: hapticsToggle, position: CGPoint(x: 80, y: -45), name: "hapticsToggle")
        
        // Haptics Toggle Background (positioned after text to center on it)
        let hapticsToggleBackground = SKSpriteNode(color: SKColor.brown.withAlphaComponent(0.8), size: CGSize(width: 80, height: 40))
        hapticsToggleBackground.position = CGPoint(x: hapticsToggle.position.x, y: hapticsToggle.position.y + hapticsToggle.frame.height/4)
        hapticsToggleBackground.zPosition = 100
        hapticsToggleBackground.name = "hapticsToggleBackground"
        addChild(hapticsToggleBackground)
    }

    func toggleSetting(named name: String) {
        let current = UserDefaults.standard.bool(forKey: name)
        UserDefaults.standard.set(!current, forKey: name)

        if name == "soundEffectsEnabled" {
            updateSFXLabel()
        } else if name == "hapticsEnabled" {
            updateHapticsLabel()
        } else if name == "musicEnabled" {
            updateMusicLabel()
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
    
    private func updateMusicLabel() {
        let isEnabled = UserDefaults.standard.bool(forKey: "musicEnabled")
        musicToggle.text = "\(isEnabled ? "ON" : "OFF")"
    }
    
    private func addToggle(label: SKLabelNode, position: CGPoint, name: String) {
        label.position = position
        label.name = name
        label.zPosition = 101
        addChild(label)

        let hitbox = SKSpriteNode(color: .clear, size: CGSize(width: 200, height: 40))
        hitbox.position = position
        hitbox.name = name
        hitbox.zPosition = 100
        addChild(hitbox)
    }

}
