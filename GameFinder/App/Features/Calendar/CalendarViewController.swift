//
//  CalendarViewController.swift
//  GameFinder
//
//  Created by Suji Jang on 12/21/25.
//

import UIKit
import SnapKit

final class CalendarViewController: BaseViewController {

    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Calendar"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)

        // Screen View 로깅
        LogManager.logScreenView("Calendar", screenClass: "CalendarViewController")
    }

    // MARK: - Setup
    private func setNavigationBar() {
        navigationItem.title = L10n.TabBar.fourth
    }

    override func configureHierarchy() {
        view.addSubview(titleLabel)
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    override func configureView() {
        super.configureView()
        setNavigationBar()
    }
}
