//
//  ViewController.m
//  acro
//
//  Created by Admin on 3/5/15.
//  Copyright (c) 2015 ramsel. All rights reserved.
//

#import "ViewController.h"
#import "ClientAPI.h"
#import "MBProgressHud.h"

static NSString *const AcronymCellIdentifier = @"AcronymCell";

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (nonatomic, strong) NSArray* objects;

- (IBAction)didTapSendButton:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    // Do any additional setup after loading the view, typically from a nib.
}

- (void) searchAbbreviation:(NSString*)abbreviation {
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[ClientAPI sharedAPI] getAcronymsForAbbreviation:abbreviation withSuccess:^(NSArray *objects) {
        
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        // Handle no returned objects with an AlertView
        if (objects.count < 1) {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No abbreviations", @"No abbreviations")
                                                              message:[NSString stringWithFormat:@"No abbreviations for that acronym."]
                                                             delegate:nil
                                                    cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                                    otherButtonTitles:nil];
            [message show];
            return;

        }

        // Load objects into table
        self.objects = objects;
        
        [self.tableView reloadData];
    
    } failure:^(NSError *error) {
        
        [MBProgressHUD hideHUDForView:self.view animated:YES];

        UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                          message:[NSString stringWithFormat:@"Error retrieving data. Please try again."]
                                                         delegate:nil
                                                cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                                otherButtonTitles:nil];
        [message show];
        
        NSLog(@"error = %@", error);

        return;

        
    }];
    
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // Order Cell
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:AcronymCellIdentifier
                                                                      forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    cell.tag = indexPath.row;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSDictionary* abbreviationDict = self.objects[indexPath.row];
    cell.textLabel.text = abbreviationDict[@"lf"];
    
    return cell;
}



- (IBAction)didTapSendButton:(id)sender {
    
    [self.textField resignFirstResponder];
    
    // TODO: Need to validate
    
    if (self.textField.text.length > 0) {
        [self searchAbbreviation:self.textField.text];
    }
    
}
@end
