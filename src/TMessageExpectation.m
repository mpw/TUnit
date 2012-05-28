//
//  TMessageExpectation.m
//  MPWTest
//
//  Created by Marcel Weiher on 5/6/11.
//  Copyright 2011 metaobject ltd. All rights reserved.
//

#pragma .h #import <Foundation/Foundation.h>
#import "TMessageExpectation.h"
#import "AccessorMacros.h"


@implementation TMessageExpectation : NSObject
{
        NSInvocation *invocationToMatch;
        int                      expectedCount;
        int                      actualMatch;
        id                       exceptionToThrow;
        NSMutableIndexSet *skippedParameters;
        BOOL            isOrdered;
}


idAccessor( exceptionToThrow, setExceptionToThrow )
objectAccessor( NSInvocation , invocationToMatch, setInvocationToMatch )
objectAccessor( NSMutableIndexSet , skippedParameters, setSkippedParameters )


-initWithInvocation:(NSInvocation*)invocation
{
	self=[super init];
	if ( self ) {
		[invocation retainArguments];
		[self setInvocationToMatch:invocation];
		[self setSkippedParameters:[NSMutableIndexSet indexSet]];
		
	}
	return self;
}

+expectationWithInvocation:(NSInvocation*)invocation
{
	return [[[self alloc] initWithInvocation:invocation] autorelease];
}

-(void)increaseActualMatch
{
	actualMatch++;
}

-(BOOL)compareInvocation:(NSInvocation*) inv1 withInvocation:(NSInvocation*)inv2
{
	if ( expectedCount > 0 && actualMatch > expectedCount ) {
//        NSLog(@"expectedCount actual %d vs expected %d",actualMatch,expectedCount);
		return NO;
	}
	if (  ![NSStringFromSelector([inv1 selector]) isEqual:NSStringFromSelector([inv2 selector])] ) {
//        NSLog(@"selectors actual '%@' vs expected:  '%@'",NSStringFromSelector([inv1 selector]),NSStringFromSelector([inv2 selector]) );
		return NO;
	} 
	NSMethodSignature *sig1=[inv1 methodSignature];
	NSMethodSignature *sig2=[inv2 methodSignature];
	if ( [sig1 numberOfArguments] != [sig2 numberOfArguments] ) {
//		NSLog(@"numArgs %d %d",[sig1 numberOfArguments] ,[sig2 numberOfArguments] );
		return NO;
	}
	//	NSLog(@"-- checking: %@",NSStringFromSelector([inv1 selector]));
	for ( int i=2;i<[sig1 numberOfArguments]; i++) {
		if ( ![[self skippedParameters] containsIndex:i] ) {
			char argbuf1[128];
			char argbuf2[128];
			bzero(argbuf1, sizeof argbuf1);
			bzero(argbuf2, sizeof argbuf2);
			[inv1 getArgument:argbuf1 atIndex:i]; 
			[inv2 getArgument:argbuf2 atIndex:i];
			const char * argType = [sig1 getArgumentTypeAtIndex:i];
//		NSLog(@"arg at index %d with type %s",i,argType);
			if ( argType ) {
				if ( *argType == 'r' ) {
					argType++;
				}
				switch (*argType) {
					case '*':
					{
						char *s1=*(char**)argbuf1;
						char *s2=*(char**)argbuf2;
						if (strcmp(s1,s2) ) {
//							NSLog(@"string arg at %d didn't match",i);
							return NO;
						}
					}
                        break;
					case '@':
					{
						id o1=*(id*)argbuf1;
						id o2=*(id*)argbuf2;
						if ( o1==o2 || !(o1==nil) || [o1 isEqual:o2] ) {
                            // match
						} else {
//							NSLog(@"object arg at %d didn't match: %@ %@",i,o1,o2);
							return NO;
                        }
					}
						break;
					case 'i':
					case 'I':
					{
						int i1=*(int*)argbuf1;
						int i2=*(int*)argbuf2;
						if ( i1 != i2 ) {
//							NSLog(@"integer arg at %d didn't match: %d %d",i,i1,i2);
							return NO;
						}
					}
						break;
					case '^':
					{
						void* p1=*(void**)argbuf1;
						void* p2=*(void**)argbuf2;
						if ( p1 != p2 ) {
//							NSLog(@"pointer arg for %@ at %d didn't match: %p %p",NSStringFromSelector([inv1 selector] ), i,p1,p2);
//							return NO;
						} else {
//                            NSLog(@"pointer arg for %@ at %d matched: %p %p",NSStringFromSelector([inv1 selector] ),i,p1,p2);
                        }
                    }
						break;
					default:
						if ( memcmp(argbuf1, argbuf2, 128 ) ) {
#if 1
							NSLog(@"arg at index %d with type %s didn't match!",i,argType);
#endif
							//						for (int j=0;j<10;j++ ) {
							//							NSLog(@"%d: %x %x",j,argbuf1[j],argbuf2[j]);
							//						}
							return NO;
						}
						
						break;
				}
			}
		} else {
//			NSLog(@"ignore parameters %d for %@",i,NSStringFromSelector([invocationToMatch selector]));
		}
		

		
	}
	if ( expectedCount == 0 ) {
		[NSException raise:@"unexpected shouldNotReceive" format:@"unexpected shouldNotReceive"];
	}
//	NSLog(@"actualMatch: %d / %d",actualMatch,expectedCount);
	return YES;
}

-(BOOL)unfulfilled
{
	return expectedCount > 0 && actualMatch < expectedCount;
}


-(BOOL)canHaveMore
{
	return expectedCount < 0 || [self unfulfilled];
}

-(void)setExpectedCount:(int)newCount
{
	expectedCount=newCount;
}

-(BOOL)matchesInvocation:(NSInvocation*)invocation
{
	return [self compareInvocation:invocation withInvocation:invocationToMatch];
}

-(void)setReturnValue:(void*)value
{
	[invocationToMatch setReturnValue:value];
	
}

-(void)getReturnValue:(void*)value
{
	[invocationToMatch getReturnValue:value];
	
}

-skipParameterChecks
{
	[self setSkippedParameters:[NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 10000)]];
	return self;
}

-skipParameterCheck:(int)parameterToIgnore
{
	[[self skippedParameters] addIndex:parameterToIgnore+1];
	return self;
}

boolAccessor( isOrdered, setIsOrdered) 


-ordered
{
	if ( expectedCount <= 0 ) {
		[NSException raise:@"can't order stubbed" format:@"can't order stubbed"];
	}
	[self setIsOrdered:YES];
	return self;
}




-description
{
    NSMutableString *description=[NSMutableString stringWithFormat:@"<%@:%p: selector: %@ expected:%d actual: %d",[self class],self,NSStringFromSelector([invocationToMatch selector]),expectedCount,actualMatch];
#if 1
    NSMethodSignature *sig1=[invocationToMatch methodSignature];
	for ( int i=2;i<[sig1 numberOfArguments]; i++) {
		if ( ![[self skippedParameters] containsIndex:i] ) {
			char argbuf1[128];
			bzero(argbuf1, sizeof argbuf1);
			[invocationToMatch getArgument:argbuf1 atIndex:i]; 
			const char * argType = [sig1 getArgumentTypeAtIndex:i];
            [description appendFormat:@", arg[%d]: ",i];
            //		NSLog(@"arg at index %d with type %s",i,argType);
			if ( argType ) {
				if ( *argType == 'r' ) {
					argType++;
				}
				switch (*argType) {
					case '*':
					{
						char *s1=*(char**)argbuf1;
                        [description appendFormat:@"'%.5s' ",s1];
					}
                        break;
					case '@':
					{
						id o1=*(id*)argbuf1;
                        [description appendFormat:@"%p/%@->'%@' ",o1,[o1 class],o1];
					}
						break;
					case 'i':
					case 'I':
					case 'q':
					{
						int i1=*(int*)argbuf1;
                        [description appendFormat:@"%d ",i1];
					}
						break;
					case '^':
					{
						void* p1=*(void**)argbuf1;
                        [description appendFormat:@"%p ",p1];
                    }
						break;
					default:
                        [description appendFormat:@"other %s",argType];
						break;
				}
			}
		}

        
		
	}
#endif
    [description appendFormat:@">"];
    return description;
}


@end
