import AddressBook
import UIKit
import XCTest

class RecordDifferencesTests: XCTestCase {
  func testSetsRecordAddition() {
    let newRecord: ABRecord = TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha")
    let recordDiff = RecordDifferences.resolveBetween(oldRecords: [], newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 1)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSetsPersonRecordChangesForFieldValues() {
    let oldRecord: ABRecord = TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha")
    let newRecordHomeAddress = makeAddress(
      street: "Suite 1173",
      zip: "95814",
      city: "Sacramento",
      state: "CA")
    let newInstantMessage = makeInstantMessage(
      service: kABPersonInstantMessageServiceSkype,
      username: "bigarnie")
    let newSocialProfile = makeSocialProfile(
      service: kABPersonSocialProfileServiceTwitter,
      url: "https://twitter.com/arnie",
      username: "arnie")
    let newRecord: ABRecord = TestRecords.makePerson(
      prefixName: "Mr.",
      firstName: "Arnold",
      nickName: "Arnie",
      middleName: "Big",
      lastName: "Alpha",
      suffixName: "Senior",
      organization: "State Council",
      jobTitle: "Manager",
      department: "Headquarters",
      phones: [(kABPersonPhoneMainLabel, "5551001002")],
      emails: [("Home", "arnold.alpha@example.com")],
      urls: [("Work", "https://exampleinc.com/")],
      addresses: [("Home", newRecordHomeAddress)],
      instantMessages: [(kABPersonInstantMessageServiceSkype, newInstantMessage)],
      socialProfiles: [(kABPersonSocialProfileServiceTwitter, newSocialProfile)],
      image: loadImage("aa-60"))
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 1)

    let singleValueChanges = recordDiff.changes.first!.singleValueChanges

    XCTAssertEqual(singleValueChanges.count, 7)

    let prefixNameChange = singleValueChanges[kABPersonPrefixProperty]!

    XCTAssertEqual(prefixNameChange, "Mr.")

    let nickNameChange = singleValueChanges[kABPersonNicknameProperty]!

    XCTAssertEqual(nickNameChange, "Arnie")

    let middleNameChange = singleValueChanges[kABPersonMiddleNameProperty]!

    XCTAssertEqual(middleNameChange, "Big")

    let suffixNameChange = singleValueChanges[kABPersonSuffixProperty]!

    XCTAssertEqual(suffixNameChange, "Senior")

    let organizationChange = singleValueChanges[kABPersonOrganizationProperty]!

    XCTAssertEqual(organizationChange, "State Council")

    let jobTitleChange = singleValueChanges[kABPersonJobTitleProperty]!

    XCTAssertEqual(jobTitleChange, "Manager")

    let departmentChange = singleValueChanges[kABPersonDepartmentProperty]!

    XCTAssertEqual(departmentChange, "Headquarters")

    let multiValueChanges = recordDiff.changes.first!.multiValueChanges

    XCTAssertEqual(multiValueChanges.count, 6)

    let phoneChanges = multiValueChanges[kABPersonPhoneProperty]!

    XCTAssertEqual(phoneChanges.count, 1)
    XCTAssertEqual(phoneChanges.first!.0, kABPersonPhoneMainLabel)
    XCTAssertEqual(phoneChanges.first!.1, "5551001002")

    let emailChanges = multiValueChanges[kABPersonEmailProperty]!

    XCTAssertEqual(emailChanges.count, 1)
    XCTAssertEqual(emailChanges.first!.0, "Home")
    XCTAssertEqual(emailChanges.first!.1, "arnold.alpha@example.com")

    let urlChanges = multiValueChanges[kABPersonURLProperty]!

    XCTAssertEqual(urlChanges.count, 1)
    XCTAssertEqual(urlChanges.first!.0, "Work")
    XCTAssertEqual(urlChanges.first!.1, "https://exampleinc.com/")

    let addressChanges = multiValueChanges[kABPersonAddressProperty]!

    XCTAssertEqual(addressChanges.count, 1)
    XCTAssertEqual(addressChanges.first!.0, "Home")
    XCTAssertEqual(addressChanges.first!.1, newRecordHomeAddress)

    let instantMessageChanges = multiValueChanges[kABPersonInstantMessageProperty]!

    XCTAssertEqual(instantMessageChanges.count, 1)
    XCTAssertEqual(instantMessageChanges.first!.0, kABPersonInstantMessageServiceSkype)
    XCTAssertEqual(instantMessageChanges.first!.1, newInstantMessage)

    let socialProfileChanges = multiValueChanges[kABPersonSocialProfileProperty]!

    XCTAssertEqual(socialProfileChanges.count, 1)
    XCTAssertEqual(socialProfileChanges.first!.0, kABPersonSocialProfileServiceTwitter)
    XCTAssertEqual(socialProfileChanges.first!.1, newSocialProfile)

    XCTAssertNotNil(recordDiff.changes.first!.imageChange)
  }

  func testSetsOrganizationRecordChangesForFieldValues() {
    let oldRecord: ABRecord = TestRecords.makeOrganization(name: "Goverment")
    let newRecord: ABRecord = TestRecords.makeOrganization(
      name: "Goverment",
      emails: [("Work", "info@gov.gov")])

    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 1)

    let singleValueChanges = recordDiff.changes.first!.singleValueChanges

    XCTAssertEqual(singleValueChanges.count, 0)

    let multiValueChanges = recordDiff.changes.first!.multiValueChanges

    XCTAssertEqual(multiValueChanges.count, 1)

    let emailChanges = multiValueChanges[kABPersonEmailProperty]!

    XCTAssertEqual(emailChanges.count, 1)
    XCTAssertEqual(emailChanges.first!.0, "Work")
    XCTAssertEqual(emailChanges.first!.1, "info@gov.gov")
  }

  func testDoesNotSetRecordChangeForNonTrackedFieldValue() {
    let oldRecord: ABRecord = TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha")
    let newRecord: ABRecord = TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha")
    Records.setValue("a note", toSingleValueProperty: kABPersonNoteProperty, of: newRecord)
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDeterminesExistingPersonRecordsByFirstAndLastName() {
    let oldRecords = [
      TestRecords.makePerson(firstName: "Arnold Alpha"),
      TestRecords.makePerson(lastName: "Arnold Alpha"),
      TestRecords.makePerson(lastName: "Alpha", organization: "Arnold"),
      TestRecords.makePerson(lastName: "Alpha", department: "Arnold"),
      TestRecords.makePerson(middleName: "Arnold", lastName: "Alpha")
    ]
    let newRecord: ABRecord = TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha")
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: oldRecords,
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 1)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDeterminesExistingOrganizationRecordsByName() {
    let oldRecord: ABRecord = TestRecords.makeOrganization(name: "Goverment")
    let newRecords = [
      TestRecords.makeOrganization(name: "Goverment"),
      TestRecords.makeOrganization(name: "School")
    ]
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: newRecords)

    XCTAssertEqual(recordDiff.additions.count, 1)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDiscriminatesNamesOfPersonAndOrganizationRecords() {
    let newRecords = [
      TestRecords.makePerson(firstName: "Goverment", lastName: ""),
      TestRecords.makeOrganization(name: "Goverment")
    ]
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [],
      newRecords: newRecords)

    XCTAssertEqual(recordDiff.additions.count, 2)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSkipsRecordAdditionForNewRecordsWithEmptyNames() {
    let newRecords = [
      TestRecords.makePerson(firstName: "", lastName: ""),
      TestRecords.makeOrganization(name: "")
    ]
    let recordDiff = RecordDifferences.resolveBetween(oldRecords: [], newRecords: newRecords)

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSkipsRecordAdditionForMultipleNewRecordsHavingSameName() {
    let newRecords = [
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha", jobTitle: "former"),
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha", jobTitle: "middle"),
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha", jobTitle: "latter"),
      TestRecords.makeOrganization(name: "Goverment"),
      TestRecords.makeOrganization(name: "Goverment"),
      TestRecords.makeOrganization(name: "Goverment")
    ]
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [],
      newRecords: newRecords)

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSkipsRecordChangeForOldRecordsWithEmptyNames() {
    let oldRecords = [
      TestRecords.makePerson(firstName: "", lastName: ""),
      TestRecords.makeOrganization(name: "")
    ]
    let newRecords = [
      TestRecords.makePerson(firstName: "", lastName: "", jobTitle: "worker"),
      TestRecords.makeOrganization(name: "", emails: [("Work", "info@gov.gov")])
    ]
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: oldRecords,
      newRecords: newRecords)

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSkipsRecordChangeForMultipleOldRecordsHavingSameName() {
    let oldRecords = [
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha"),
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha"),
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha"),
      TestRecords.makeOrganization(name: "Goverment"),
      TestRecords.makeOrganization(name: "Goverment"),
      TestRecords.makeOrganization(name: "Goverment")
    ]
    let newRecords = [
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha", jobTitle: "worker"),
      TestRecords.makeOrganization(name: "Goverment", emails: [("Work", "info@gov.gov")])
    ]
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: oldRecords,
      newRecords: newRecords)

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSkipsRecordChangeForMultipleNewRecordsHavingSameName() {
    let oldRecords = [
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha"),
      TestRecords.makeOrganization(name: "Goverment")
    ]
    let newRecords = [
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha", jobTitle: "former"),
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha", jobTitle: "middle"),
      TestRecords.makePerson(firstName: "Arnold", lastName: "Alpha", jobTitle: "latter"),
      TestRecords.makeOrganization(name: "Goverment", emails: [("Work", "former@gov.gov")]),
      TestRecords.makeOrganization(name: "Goverment", emails: [("Work", "middle@gov.gov")]),
      TestRecords.makeOrganization(name: "Goverment", emails: [("Work", "latter@gov.gov")])
    ]
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: oldRecords,
      newRecords: newRecords)

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDoesNotSetRecordChangeForExistingValueOfSingleValueField() {
    let oldRecord: ABRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      jobTitle: "Manager")
    let newRecord: ABRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      jobTitle: "Governor")
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDoesNotSetRecordChangeForExistingImage() {
    let oldRecord: ABRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      image: loadImage("aa-60"))
    let newRecord: ABRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      image: loadImage("bb-60"))
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testDoesNotSetRecordChangeForExistingValueOfMultiStringValueField() {
    let oldRecord: ABRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      phones: [(kABPersonPhoneMobileLabel, "5551001001")])
    let newRecord: ABRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      phones: [(kABPersonPhoneMainLabel, "5551001001")])
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSetsRecordChangeForNewValueForMultiStringValueField() {
    let oldRecord: ABRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      phones: [(kABPersonPhoneMobileLabel, "5551001001")])
    let newRecord: ABRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      phones: [(kABPersonPhoneMainLabel, "5551001002")])
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 1)

    let changes = recordDiff.changes.first!.multiValueChanges

    XCTAssertEqual(changes.count, 1)

    let (propertyChange, valueChanges) = changes.first!

    XCTAssertEqual(propertyChange, kABPersonPhoneProperty)
    XCTAssertEqual(valueChanges.count, 1)
    XCTAssertEqual(valueChanges.first!.0, kABPersonPhoneMainLabel)
    XCTAssertEqual(valueChanges.first!.1, "5551001002")
  }

  func testDoesNotSetRecordChangeForExistingValueOfMultiDictionaryValueField() {
    let addr = makeAddress(street: "Street 1", zip: "00001", city: "City", state: "CA")
    let oldRecord: ABRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      addresses: [("Home", addr)])
    let newRecord: ABRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      addresses: [("Work", addr)])
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 0)
  }

  func testSetsRecordChangeForNewValueOfMultiDictionaryValueField() {
    let oldAddr = makeAddress(street: "Street 1", zip: "00001", city: "City", state: "CA")
    let newAddr = makeAddress(street: "Street 2", zip: "00001", city: "City", state: "CA")
    let oldRecord: ABRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      addresses: [("Home", oldAddr)])
    let newRecord: ABRecord = TestRecords.makePerson(
      firstName: "Arnold",
      lastName: "Alpha",
      addresses: [("Work", newAddr)])
    let recordDiff = RecordDifferences.resolveBetween(
      oldRecords: [oldRecord],
      newRecords: [newRecord])

    XCTAssertEqual(recordDiff.additions.count, 0)
    XCTAssertEqual(recordDiff.changes.count, 1)

    let changes = recordDiff.changes.first!.multiValueChanges

    XCTAssertEqual(changes.count, 1)

    let (propertyChange, valueChanges) = changes.first!

    XCTAssertEqual(propertyChange, kABPersonAddressProperty)
    XCTAssertEqual(valueChanges.count, 1)
    XCTAssertEqual(valueChanges.first!.0, "Work")
    XCTAssertEqual(valueChanges.first!.1, newAddr)
  }

  private func makeAddress(
    #street: String,
    zip: String,
    city: String,
    state: String)
    -> [String: String]
  {
    return [
      kABPersonAddressStreetKey: street,
      kABPersonAddressZIPKey: zip,
      kABPersonAddressCityKey: city,
      kABPersonAddressStateKey: state
    ]
  }

  private func makeInstantMessage(#service: String, username: String)
    -> [String: String]
  {
    return [
      kABPersonInstantMessageServiceKey: service,
      kABPersonInstantMessageUsernameKey: username
    ]
  }

  private func makeSocialProfile(
    #service: String,
    url: String,
    username: String)
    -> [String: String]
  {
    return [
      kABPersonSocialProfileServiceKey: service,
      kABPersonSocialProfileURLKey: url,
      kABPersonSocialProfileUsernameKey: username
    ]
  }

  private func loadImage(filename: String) -> UIImage {
    let path = NSBundle(forClass: RecordDifferencesTests.self).pathForResource(filename, ofType: "png")
    return UIImage(contentsOfFile: path!)!
  }
}
