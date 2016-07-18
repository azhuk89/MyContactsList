//
//  Contact.m
//  ContactsList
//
//  Created by Alexandr Zhuk on 7/13/16.
//  Copyright © 2016 Alexandr Zhuk. All rights reserved.
//

#import "Contact.h"

@implementation Contact

-(id)initWithContactName:(NSString *)contactName andPhoneNumber:(NSString *)phoneNumber {
    if (self = [super init]) {
        _contactName = contactName;
        _phoneNumber = phoneNumber;
    }
    return self;
}

@end