//
//  AJCountryPicker.swift
//  AJCountryPicker
//
//  Created by Aj Mehra on 25/07/16.
//  Copyright © 2016 TeamAj. All rights reserved.
//

import UIKit

@objc public protocol AJCountryPickerDelegate: class {
	func ajCountryPicker(_ picker: AJCountryPicker, didSelectCountryWithName name: String, code: String)
	@objc optional func ajCountryPicker(_ picker: AJCountryPicker, didSelectCountryWithName name: String, code: String, dialCode: String)
	@objc optional func ajCountryPicker(_ picker: AJCountryPicker, didSelectCountryWithName name: String, code: String, dialCode: String, flag: UIImage?)

}

open class AJCountryPicker: UITableViewController {

	// MARK:- Constants

	let countryCellIdentifier = "AJCountryCell"

	// MARK:- Variables
	// MARK: ..... Public Variables
	open var customCountriesCode: [String]?
	open var showCountryFlags = true
	open var showSection = false
	open var showSearchBar = true
	open weak var delegate: AJCountryPickerDelegate?
	open var countryWithCode: ((String, String) -> ())?
	open var countryWithCodeAndCallingCode: ((String, String, String) -> ())?
	open var countryWithFlagAndCallingCode: ((String, String, String, UIImage?) -> ())?
	open var showCallingCodes = false

	// MARK: ..... Private Variables
	fileprivate var searchController: UISearchController!
	fileprivate var filteredList = [AJCountry]()

	fileprivate var allCountries: [AJCountry] {
		let locale = Locale.current
		var unsourtedCountries = [AJCountry]()
		let countriesCodes = customCountriesCode == nil ? Locale.isoRegionCodes : customCountriesCode!

		for countryCode in countriesCodes {
			let displayName = (locale as NSLocale).displayName(forKey: NSLocale.Key.countryCode, value: countryCode)
			let countryData = AJCallingCodes.filter { $0["code"] == countryCode }
			let country: AJCountry
			if countryData.count > 0, let dialCode = countryData[0]["dialCode"] {
				country = AJCountry(name: displayName!, code: countryCode, dialCode: dialCode)
			} else {
				country = AJCountry(name: displayName!, code: countryCode)
			}
			unsourtedCountries.append(country)
		}
		return unsourtedCountries
	}

	fileprivate var sections: [Section] {
		let countries: [AJCountry] = allCountries.map { country in
			let country = AJCountry(name: country.name, code: country.code, dialCode: country.dialCode)
			country.section = collation.section(for: country, collationStringSelector: #selector(getter: AJCountry.name))
			return country
		}

		// create empty sections
		var sections = [Section]()
		for _ in 0..<self.collation.sectionIndexTitles.count {
			sections.append(Section())
		}

		// put each country in a section
		for country in countries {
			sections[country.section!].addCountry(country)
		}

		// sort each section
		for section in sections {
			var s = section
			s.countries = collation.sortedArray(from: section.countries, collationStringSelector: #selector(getter: AJCountry.name)) as! [AJCountry]
		}

		return sections
	}

	fileprivate let collation = UILocalizedIndexedCollation.current()
	as UILocalizedIndexedCollation

	// MARK:- Initalizer
	convenience public init(completionHandler: @escaping ((String, String) -> ())) {
		self.init()
		self.countryWithCode = completionHandler

	}

	// MARK:- View Life Cycle
	override open func viewDidLoad() {
		super.viewDidLoad()
		initUI()
		// Do any additional setup after loading the view.
	}

	override open func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: Private Methods

	fileprivate func createSearchBar() {
		if self.tableView.tableHeaderView == nil {
			searchController = UISearchController(searchResultsController: nil)
			searchController.searchResultsUpdater = self
			searchController.dimsBackgroundDuringPresentation = false
			tableView.tableHeaderView = searchController.searchBar
		}
	}

	fileprivate func filter(_ searchText: String) -> [AJCountry] {
		filteredList.removeAll()
		sections.forEach { (section) -> () in
			section.countries.forEach({ (country) -> () in
				if country.name.characters.count >= searchText.characters.count {
					let result = country.name.compare(searchText, options: [.caseInsensitive, .diacriticInsensitive], range: searchText.range(of: searchText))
					if result == .orderedSame {
						filteredList.append(country)
					}
				}
			})
		}

		return filteredList
	}

	fileprivate func initUI() -> Void {
		definesPresentationContext = true
		if isModal () {
			tableView.contentInset.top = 20
		}

		if showSearchBar {
			createSearchBar()
		}
		filteredList = allCountries
		tableView.reloadData()
	}

	fileprivate func isModal() -> Bool {
		if self.presentingViewController != nil {
			return true
		}

		if self.presentingViewController?.presentedViewController == self {
			return true
		}

		if self.navigationController?.presentingViewController?.presentedViewController == self.navigationController {
			return true
		}

		if self.tabBarController?.presentingViewController is UITabBarController {
			return true
		}

		return false
	}

}
//MARK:- Table View Data Source
extension AJCountryPicker {

	open override func numberOfSections(in tableView: UITableView) -> Int {
		if searchController.searchBar.isFirstResponder || !showSection {
			return 1
		}
		return sections.count
	}
	open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

		if searchController.searchBar.isFirstResponder || !showSection {
			return filteredList.count
		}
		return sections[section].countries.count
	}
	open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return self.tableView(tableView, countryCellForRowAtIndexPath: indexPath)
	}
	func tableView(_ tableView: UITableView, countryCellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
		var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: countryCellIdentifier)
		if cell == nil {
			cell = UITableViewCell(style: .value1, reuseIdentifier: countryCellIdentifier)
		}

		let country: AJCountry!

		if searchController.searchBar.isFirstResponder || !showSection {
			country = filteredList[indexPath.row]
		} else {
			country = sections[indexPath.section].countries[indexPath.row]

		}

		cell!.textLabel?.text = country.name
		cell?.textLabel?.font = UIFont.systemFont(ofSize: 13, weight: 0.1)
		cell!.textLabel?.numberOfLines = 0
		if showCallingCodes {
			cell!.detailTextLabel?.text = country.dialCode
			cell!.detailTextLabel?.font = UIFont.systemFont(ofSize: 14)
		}

		if showCountryFlags {
			let bundle = "assets.bundle/"
			cell!.imageView!.image = UIImage(named: bundle + country.code.lowercased() + ".png", in: Bundle(for: AJCountryPicker.self), compatibleWith: nil)
			let itemSize = CGSize(width: 35, height: 25)
			UIGraphicsBeginImageContextWithOptions(itemSize, false, UIScreen.main.scale)
			let imageRect = CGRect(x: 0.0, y: 0.0, width: itemSize.width, height: itemSize.height)
			cell!.imageView?.image?.draw(in: imageRect)
			cell!.imageView?.image = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
		}

		return cell!
	}

	override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if !showSection {
			return ""
		}
		if !sections[section].countries.isEmpty {
			return self.collation.sectionTitles[section] as String
		}
		return ""
	}

	override open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
		if !showSection {
			return []
		}
		return collation.sectionIndexTitles
	}

	override open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
		if !showSection {
			return 0
		}
		return collation.section(forSectionIndexTitle: index)
	}
}
// MARK: - Table view delegate

extension AJCountryPicker {
	override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		let country: AJCountry!
		if searchController.searchBar.isFirstResponder || !showSection {
			country = filteredList[indexPath.row]
		} else {
			country = sections[indexPath.section].countries[indexPath.row]

		}
		delegate?.ajCountryPicker(self, didSelectCountryWithName: country.name, code: country.code)
		delegate?.ajCountryPicker?(self, didSelectCountryWithName: country.name, code: country.code, dialCode: country.dialCode)
		countryWithCode?(country.name, country.code)
		countryWithCodeAndCallingCode?(country.name, country.code, country.dialCode)
		let bundle = "assets.bundle/"
		let image = UIImage(named: bundle + country.code.lowercased() + ".png", in: Bundle(for: AJCountryPicker.self), compatibleWith: nil)
		countryWithFlagAndCallingCode?(country.name, country.code, country.dialCode, image)
		delegate?.ajCountryPicker?(self, didSelectCountryWithName: country.name, code: country.code, dialCode: country.dialCode, flag: image)
		self.dismiss(animated: true, completion: nil)
		let _ = self.navigationController?.popViewController(animated: true)
	}
}
// MARK: - UISearchDisplayDelegate
extension AJCountryPicker: UISearchResultsUpdating {
	public func updateSearchResults(for searchController: UISearchController) {
		let _ = filter(searchController.searchBar.text!)
		tableView.reloadData()
	}
}
