//
//  Contact.m
//  ContactsList
//
//  Created by Alexandr Zhuk on 7/13/16.
//  Copyright © 2016 Alexandr Zhuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Contact : NSObject

@property (nonatomic) NSString *contactName;
@property (nonatomic) NSString *phoneNumber;
@property (nonatomic) NSString *sortField;

-(id)initWithContactName:(NSString *)contactName andPhoneNumber:(NSString *)phoneNumber;

@end