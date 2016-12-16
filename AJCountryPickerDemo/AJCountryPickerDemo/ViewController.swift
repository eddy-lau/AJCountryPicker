//
//  ViewController.swift
//  AJCountryPickerDemo
//
//  Created by Aj Mehra on 26/07/16.
//  Copyright © 2016 TeamAj. All rights reserved.
//

import UIKit
import AJCountryPicker2

class ViewController: UIViewController {

	// MARK:- IBOulets
	@IBOutlet weak var label: UILabel!
    
    let defaultCountry = "US"
    
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
        label.text = "Selected Country: " + (Locale.current as NSLocale).displayName(forKey: .countryCode, value: defaultCountry)!
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK:- IBActions
	@IBAction func selectCountryButtonTapped(_ sender: UIButton) -> Void {
		let picker = AJCountryPicker { (country, code) -> () in
			self.label.text = "Selected Country: " + country
		}

		// Optional: To pick from custom countries list
		picker.customCountriesCode = ["EG", "US", "AF", "AQ", "AX", "IN"]
        
        // Optional: The initial selection
        picker.selectedCountryCode = defaultCountry

		// delegate
		picker.delegate = self

		// Display calling codes
		picker.showCallingCodes = true

		// or closure
		picker.countryWithCode = { (country, code) -> () in
			// picker.navigationController?.popToRootViewControllerAnimated(true)
		}
		navigationController?.pushViewController(picker, animated: true)
		//navigationController?.presentViewController(picker, animated: true, completion: nil)
        
	}
}

extension ViewController: AJCountryPickerDelegate {
	func ajCountryPicker(_ picker: AJCountryPicker, didSelectCountryWithName name: String, code: String) {
		label.text = "Selected Country: \(name)"
        _ = navigationController?.popViewController(animated: true)
	}
}
