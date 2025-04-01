

protocol Service {

    var shouldAutostart: Bool { get }

    func start()
    func stop()
}
