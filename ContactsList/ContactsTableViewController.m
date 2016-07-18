//
//  ContactsTableViewController.m
//  ContactsList
//
//  Created by Alexandr Zhuk on 7/13/16.
//  Copyright © 2016 Alexandr Zhuk. All rights reserved.
//

#import "ContactsTableViewController.h"
#import "ContactTableViewCell.h"
#import "Contact.h"
#import "Constants.h"

@import AddressBook;

@interface ContactsTableViewController ()

@property (nonatomic, strong) NSMutableArray *contacts;

@end

@implementation ContactsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    [self loadContacts];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.contacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    Contact *contact = self.contacts[indexPath.row];
        
    if (![contact.contactName isEqualToString:@""] && ![contact.phoneNumber isEqualToString:@""]) {
        cell.contactLabel.text = [NSString stringWithFormat:@"%@ / %@", contact.contactName, contact.phoneNumber];
    } else if (![contact.contactName isEqualToString:@""]) {
        cell.contactLabel.text = contact.contactName;
    } else if (![contact.phoneNumber isEqualToString:@""]) {
        cell.contactLabel.text = contact.phoneNumber;
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row % 2 == 0) {
        cell.backgroundColor = [UIColor whiteColor];
    } else {
        cell.backgroundColor = [UIColor colorWithRed:204.0/255.0 green:204.0/255.0 blue:204.0/255.0 alpha:1.0];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Contact *contact = self.contacts[indexPath.row];
    
    if (![contact.phoneNumber isEqualToString:@""]) {
        [self callToNumber:contact.phoneNumber];
    } else {
        [self showAlertWithTitle:PHONE_CALL_ALERT_TITLE andMessage:NO_PHONE_NUMBER_ALERT_MESSAGE];
    }
}



#pragma mark - app logic

-(void)loadContacts {
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied || ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted) {
        NSLog(@"AddressBook: access denied");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertWithTitle:ACCESS_DENIED_ALERT_TITLE andMessage:ACCESS_DENIED_ALERT_MESSAGE];
        });
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        NSLog(@"AddressBook: access authorized");
        [self getContactsData];
    } else {
        NSLog(@"AddressBook: status not determined");
        ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
            if (!granted) {
                NSLog(@"AddressBook: access denied by user");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showAlertWithTitle:ACCESS_DENIED_ALERT_TITLE andMessage:ACCESS_DENIED_ALERT_MESSAGE];
                });
                return;
            }
            NSLog(@"AddressBook: access authorized by user");
            [self getContactsData];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        });
    }
}

-(void)getContactsData {
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, nil);
    NSArray *allContacts = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBookRef);
    self.contacts = [NSMutableArray new];
    
    for (id record in allContacts) {
        Contact *contact = [[Contact alloc] init];
        ABRecordRef contactRef = (__bridge ABRecordRef)record;
        
        NSString *contactName = (__bridge NSString*)ABRecordCopyCompositeName(contactRef);
        NSLog(@"name: %@", contactName);
        
        NSString *firstName = (__bridge NSString*)ABRecordCopyValue(contactRef, kABPersonFirstNameProperty);
        NSString *lastName = (__bridge NSString*)ABRecordCopyValue(contactRef, kABPersonLastNameProperty);
        NSString *middleName = (__bridge NSString*)ABRecordCopyValue(contactRef, kABPersonMiddleNameProperty);
        NSLog(@"firstName: %@", firstName);
        NSLog(@"lastName: %@", lastName);
        NSLog(@"middleName: %@", middleName);
        
        if (firstName && lastName) {
            contact.contactName = [NSString stringWithFormat:@"%@ %@ %@", firstName, middleName ? middleName : @"", lastName];
            contact.sortField = lastName;
        } else {
            contact.contactName = contactName ? contactName : @"";
            contact.sortField = contact.contactName;
        }
        
        ABMultiValueRef phoneNumbers = ABRecordCopyValue(contactRef, kABPersonPhoneProperty);
        if (ABMultiValueGetCount(phoneNumbers) > 0) {
            NSString *mobileNumber = nil;
            NSString *iphoneNumber = nil;
            NSString *mainNumber = nil;
            NSString *someNumber = nil;
            for (CFIndex i = 0; i < ABMultiValueGetCount(phoneNumbers); i++) {
                CFStringRef label = ABMultiValueCopyLabelAtIndex(phoneNumbers, i);
                if (label && CFEqual(label, kABPersonPhoneMobileLabel)) {
                    mobileNumber = (__bridge NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, i);
                } else if (label && CFEqual(label, kABPersonPhoneIPhoneLabel)) {
                    iphoneNumber = (__bridge NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, i);
                } else if (label && CFEqual(label, kABPersonPhoneMainLabel)) {
                    mainNumber = (__bridge NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, i);
                } else if (label) {
                    someNumber = (__bridge NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, i);
                }
            }
            
            if (mobileNumber) contact.phoneNumber = mobileNumber;
            else if (iphoneNumber) contact.phoneNumber = iphoneNumber;
            else if (mainNumber) contact.phoneNumber = mainNumber;
            else contact.phoneNumber = someNumber;
        }
        
        if (!contact.phoneNumber) contact.phoneNumber = @"";
        NSLog(@"phone number: %@", contact.phoneNumber);
        [self.contacts addObject:contact];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sortField" ascending:YES];
    [self.contacts sortUsingDescriptors:@[sortDescriptor]];
}

-(void)callToNumber:(NSString *)phoneNumber {
    NSURL *phoneURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", phoneNumber]];
    if ([[UIApplication sharedApplication] canOpenURL:phoneURL]) {
        [[UIApplication sharedApplication] openURL:phoneURL];
    } else {
        [self showAlertWithTitle:PHONE_CALL_ALERT_TITLE andMessage:PHONE_CALL_ALERT_MESSAGE];
    }
}

-(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(title, nil) message:NSLocalizedString(message, nil) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alert show];
}

@end
