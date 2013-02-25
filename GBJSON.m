/*
 GBJSON.m
 
 Copyright 02/23/2013 Guillaume Bohr
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "GBJSON.h"
#import <objc/runtime.h>

@implementation GBJSON

+ (id)parseJSONObject:(id)anObject usingClass:(Class)aClass provider:(id)aProvider
{
    if ([anObject isKindOfClass:[NSArray class]])
    {
        // Cast object to array
        NSArray *objectsArray = (NSArray*)anObject;
        
        // Create structure to receive objects
        NSMutableArray *dataMutableArray = [NSMutableArray new];
        
        // Iterates over all objects
        for (id currentObject in objectsArray)
        {
            [dataMutableArray addObject:[GBJSON parseJSONObject:currentObject usingClass:aClass provider:aProvider]];
        }
        
        // Return completed
        return dataMutableArray;
    }
    else if ([anObject isKindOfClass:[NSDictionary class]])
    {
        // Cast object to dictionary
        NSDictionary *objectDictionary = (NSDictionary*)anObject;
        
        // Get dictionary keys
        NSArray *dictionaryKeys = [objectDictionary allKeys];
        
        // Get varibles for the current class
        NSDictionary *variables = [GBJSON getClassVariables:aClass];
        
        // Get varibles names
        NSArray *variablesNames = [variables allKeys];
        
        // Create object that will receive parsed objects
        id receiver = [aClass new];
        
        // Iterates over all keys
        for (NSString *key in dictionaryKeys)
        {
            // Check that key is present in variables names
            if ([variablesNames containsObject:key])
            {
                // Get JSON object for current variable
                id variableObject = [objectDictionary objectForKey:key];
                
                // Get current variable class name
                NSString *variableClassName = [variables objectForKey:key];
                
                // Check if it's an object or a scalar
                if ([variableClassName hasPrefix:@"@"])
                {
                    // Special case of arrays because they are not strongly typed in Objective-C
                    if ([variableObject isKindOfClass:[NSArray class]])
                    {
                        // Get current variable class using provider
                        if ([[aProvider class] conformsToProtocol:@protocol(GBJSONProvider)] && [aProvider respondsToSelector:@selector(getClassForElementsInArrayNamed:)])
                        {
                            // Get current variable class
                            Class variableClass = [aProvider getClassForElementsInArrayNamed:key];
                            
                            // Check class
                            if (variableClass)
                            {
                                // Set current variable
                                [receiver setValue:[GBJSON parseJSONObject:variableObject usingClass:variableClass provider:aProvider] forKey:key];
                            }
                            else
                            {
                                // No Class returned by GBJSON provider
                                NSLog(@"Class %@ did not return Class for elements in array named %@", [aProvider class], key);
                            }
                        }
                        else
                        {
                            // Not conform to GBJSON provider protocol
                            NSLog(@"Class %@ does not conform to protocol GBJSONProvider", [aProvider class]);
                        }
                    }
                    else
                    {
                        // Remove useless characters from variable class name
                        variableClassName = [variableClassName stringByReplacingOccurrencesOfString:@"@" withString:@""];
                        variableClassName = [variableClassName stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                        
                        // Get current variable class
                        Class variableClass = NSClassFromString(variableClassName);
                        
                        // Set current variable
                        [receiver setValue:[GBJSON parseJSONObject:variableObject usingClass:variableClass provider:aProvider] forKey:key];
                    }
                }
                else
                {
                    if ([variableObject isKindOfClass:[NSNumber class]])
                    {
                        // Set current scalar
                        [receiver setValue:variableObject forKey:key];
                    }
                    else if ([variableObject isKindOfClass:[NSString class]])
                    {
                        // A string representing a scalar or an enum value
                        if ([[aProvider class] conformsToProtocol:@protocol(GBJSONProvider)] && [aProvider respondsToSelector:@selector(getNSNumberForString:)])
                        {
                            NSString *stringObject = (NSString *)variableObject;
                            [receiver setValue:[aProvider getNSNumberForString:stringObject] forKey:key];
                        }
                        else
                        {
                            // Not conform to GBJSON provider protocol
                            NSLog(@"Class %@ does not conform to protocol GBJSONProvider", [aProvider class]);
                        }
                    }
                    else
                    {
                        // Unknown scalar type
                        NSLog(@"Class %@ is not a valid wrapper for scalar type", [variableObject class]);
                    }
                }
            }
            else
            {
                // Unknown variable name
                NSLog(@"Class %@ do not contain a variable named %@", aClass, key);
            }
        }
        
        // Return completed object
        return receiver;
    }
    else if ([anObject isKindOfClass:[NSString class]] && aClass == [NSString class])
    {
        // Return the NSString as is
        return anObject;
    }
    else if ([anObject isKindOfClass:[NSString class]])
    {
        // Ask how to format the string
        if ([[aProvider class] conformsToProtocol:@protocol(GBJSONProvider)] && [aProvider respondsToSelector:@selector(getObjectForClass:fromString:)])
        {
            NSString *stringObject = (NSString *)anObject;
            return [aProvider getObjectForClass:aClass fromString:stringObject];
        }
        else
        {
            // Not conform to GBJSON provider protocol
            NSLog(@"Class %@ does not conform to protocol GBJSONProvider", [aProvider class]);
        }
    }
    
    // Return nil if the object is unknown
    NSLog(@"Unknown object: %@ , returned nil", [anObject class]);
    return nil;
}

+ (NSDictionary*)getClassVariables:(Class)aClass
{
    // Count number of variables
    unsigned int ivarsCount = 0;
    Ivar *ivars = class_copyIvarList(aClass, &ivarsCount);
    
    // Create mutable dictionary to store variables names and classes
    NSMutableDictionary *variables = [NSMutableDictionary new];
    
    // Iterate over variables
    for(int i = 0; i < ivarsCount; i++)
    {
        // Retrieve variable at index i
        Ivar ivar = ivars[i];
        
        // Retrieve variable name
        NSString *varName = [NSString stringWithCString:ivar_getName(ivar) encoding:NSStringEncodingConversionAllowLossy];
        
        // Remove _ at the beginning of variable name
        if ([varName hasPrefix:@"_"])
        {
            varName = [varName substringFromIndex:1];
        }
        
        // Retrieve variable class
        NSString *varClass = [NSString stringWithCString:ivar_getTypeEncoding(ivar) encoding:NSStringEncodingConversionAllowLossy];
        
        // Save variable information into the dictionary
        [variables setObject:varClass forKey:varName];
    }
    
    // Release memory
    free(ivars);
    
    // Return result
    return variables;
}

@end
