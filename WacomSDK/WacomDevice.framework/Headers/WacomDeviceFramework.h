/*--------------------------------------------------------------------------------------------------

 FILE NAME

 WacomDeviceFramework.h

 Abstract: Act as a container and manager for UITouches and perform touch rejection

 Version: 2.0.11
 
 COPYRIGHT
 Copyright WACOM Technology, Inc. 2012-2014
 All rights reserved.

 --------------------––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––-––-----*/

#ifndef WACOMDEVICEFRAMEWORK_H //{
#define WACOMDEVICEFRAMEWORK_H
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "TrackedTouch.h"
#define WAC_ERROR (-1)
#define WAC_SUCCESS 0


#pragma mark -
#pragma mark "Stylus Event"
#pragma mark -

typedef enum {
	eStylusEventType_PressureChange,
	eStylusEventType_ButtonPressed = 1,
	eStylusEventType_ButtonReleased = 2,
	eStylusEventType_BatteryLevelChanged = 3,
	eStylusEventType_MACAddressAvaiable = 4,
	eStylusEventType_NameUpdated = 5,
	eStylusEventType_ManufacturerUpdated = 6,
	eStylusEventType_FirmwareVersionUpdated = 7,
	eStylusEventType_SoftwareVersionUpdated = 8
} WacomStylusEventType;

extern NSString *kAlarmServiceEnteredBackgroundNotification;
extern NSString *kAlarmServiceEnteredForegroundNotification;
extern NSString *kAlarmBluetoothPowerOffNotification;
extern NSString *kAlarmBluetoothPowerOnNotification;


//! @class WacomStylusEvent
//! @abstract Serves the purpose of supplying stylus data to the shimmed views and view controllers, as
//! well as the callback.
@interface WacomStylusEvent : NSNotification <NSCopying>



//! @function getType
//! @returns a WacomStylusEventType to determine what kind of event is coming through.
- (WacomStylusEventType) getType;



//! @function getPressure
//! @returns a CGFloat representing the pressure that was received from the stylus
- (CGFloat)getPressure;



//! @function getButton
//! @returns a uint representing the button number for which the button event is happening
- (unsigned long)getButton;



//! @function getBatteryLevel
//! @returns a uint representing the remaining battery life in percent form.
- (unsigned long)getBatteryLevel;



//! @function getMACAddress
//! @returns the MAC Address that was updated.
- (NSString *) getMACAddress;



//! @function getFirmwareVersion
//! @returns the firmware verison that was updated.
- (NSString *) getFirmwareVersion;



//! @function getName
//! @returns the device name that was updated.
- (NSString *) getName;



//! @function getManufacturer
//! @returns the manufacturer that was updated.
- (NSString *) getManufacturer;



//! @function getSoftwareVersion
//! @returns the software version that was updated.
- (int)getSoftwareVersion;

@end // @interface WacomStylusEvent



#pragma mark -
#pragma mark "Device Object"
#pragma mark -
//! allows a differentiation between tips if there is more than one
typedef enum { eTipType_TipInvalid, eTipType_TipPen} WacomStylusTipType;

//! allows the differentiation between device types if there is one
typedef enum { eDeviceType_Stylus} WacomDeviceType;

//! specifies button states such as pushed down or up
typedef enum { eButtonState_Invalid, eButtonState_Down, eButtonState_Up} WacomStylusButtonState;



//! @class WacomDevice
//! @abstract Provides a object where a device can be identified and attributes determined.
@interface WacomDevice : NSObject <NSCopying>



//! @function getMacAddress
//! @returns the unique id for this device (Bluetooth address) in string form.
-(NSString *) getMacAddress;



//! @function getDeviceType
//! @returns a WacomDeviceType to determine if you are using a stylus or a Wacom tablet with a stylus
-(WacomDeviceType) getDeviceType;



//! @function getButtonCount
//! @returns a button count that can then be used with a loop to walk through the buttons.
-(uint) getButtonCount;



//! @function getButtonStateWithButtonIndex
//! @returns the state of the requested button.
-(WacomStylusButtonState) getButtonStateWithButtonIndex:(uint) button_I;



//! @function supportsPressure
//! @returns YES/NO based on whether the device supports pressure events.
-(BOOL) supportsPressure;



//! @function getMaxPressure
//! @returns the maximum pressure reading that can be supplied by the stylus. The range will
//! always start from 0
-(NSInteger) getMaximumPressure;



//! @function getMinumum Pressure
//! @returns the minimum pressure reading that can be supplied by the stylus. This value will always
//! be 0.
-(NSInteger) getMinimumPressure;



//! @function getName
//! @returns  the name of the device, such as "Wacom Intuos Creative Stylus"
-(NSString *) getName;



//! @function getShortName
//! @returns  the name of the device, such as "Wacom"
-(NSString *) getShortName;



//! @function getManufacturerName
//! @returns  the manufacturer of the device "Wacom Co. Ltd."
-(NSString *) getManufacturerName;



//! @function getFirmwareVersion
//! @returns the version of the firmware
-(NSString *) getFirmwareVersion;



//! @function getSoftwareVersion
//! @returns returns the stylus' software version.
-(int) getSoftwareVersion;



//! @function getUUIDAsNSString
//! @returns an NSString which contains the value of the UUID.
-(NSString *) getUUIDAsNSString;
 


//! @function printDeviceInfo
//! @discussion prints out the information about this device.
-(void)printDeviceInfo;



//! @function isCurrentlyConnected
//! @returns YES if the device is currently connected
-(BOOL) isCurrentlyConnected;



//! @function getSignalStrength
//! @returns the strength of the signal in db higher is -1 being better than -2.
-(int)getSignalStrength;



//! @function getPeripheral
//! @returns the peripheral provided by CoreBluetooth
-(CBPeripheral *) getPeripheral;

@end // @interface WacomDevice


#pragma mark -
#pragma mark "Device Manager"
#pragma mark -


//! @abstract Singleton for accessing accessing devices and for registering for notifications.

@interface WacomManager: NSObject

//! @function getManager
//! @returns a pointer to the singleton that is the WacomManager.
+ (WacomManager *) getManager;



//! @function getDevices
//! @returns a pointer an NSArray of devices.
- (NSArray *)getDevices;



//! @function registerForNotifications
//! @returns WAC_ERROR or WAC_SUCCESS if the registration call was successful
- (int) registerForNotifications:(id)registrant_I;



//! @function unregisterForNotifications
//! @returns WAC_ERROR or WAC_SUCCESS if the unregistration call was successful
- (int) deregisterForNotifications:(id)registrant_I;


//! @function setMinimumSignalStrength
//! @returns nothing
//! @discussion this function sets the minimum signal strength required to returned as a discovered device
//! the default is -60
-(void) setMinimumSignalStrength:(int)minimum_I;



//! @function getMinimumSignalStrength
//! @returns an integer repreesenting the minimum signal strength required for a device to be
//! returned from the discovery process
-(int) getMinimumSignalStrength;


//! @function startDeviceDiscovery
//! @returns WAC_ERROR or WAC_SUCCESS depending.
//! @discussion upon return of this function you can query the manager for the devices using the getDevices
//! method
- (int) startDeviceDiscovery;



//! @function stopDeviceDiscovery
//! @returns WAC_ERROR or WAC_SUCCESS depending.
//! @discussion upon return of this function you can query the manager for the devices using the getDevices
//! method
- (int) stopDeviceDiscovery;



//! @function reconnectToStoredDevices
//! @discussion this will cause the WacomManager to try to reconnect to previously connected devices
-(void) reconnectToStoredDevices;



//! @property isDiscoveryInProgress
//! @discussion a simple BOOL to indicate whether or not discovery is in progess or not.
@property (readonly) BOOL isDiscoveryInProgress;



//! @function selectDevice
//! @returns WAC_ERROR or WAC_SUCCESS depending.
//! @discussion tells the singleton to provide updates from this device.
- (int) selectDevice:(WacomDevice *)device;



//! @function deselectDevice
//! @returns WAC_ERROR or WAC_SUCCESS depending.
//! @discussion tells the singleton to stop providing updates from this device.
-(int) deselectDevice:(WacomDevice *)device;



//! @function getSelectedDevice
//! @returns the device that has been selected for use.
-(WacomDevice *) getSelectedDevice;



//! @function isADeviceSelected
//! @returns returns true if a device is selected for use, otherwise false
- (BOOL) isADeviceSelected;



//! @function getSDKVersion
//! @returns returns the SDK version string.
-(NSString *) getSDKVersion;



//! @discussion it is possible to have more than one stylus connected at a time so this is the array of services.
@property (retain, nonatomic) NSMutableArray *connectedServices;



//! @discussion tracks the touches that the SDK knows about.
-(TouchManager *)currentlyTrackedTouches;



//! @function didEnterBackgroundNotification
//! @returns returns the SDK version string.
- (void)didEnterBackgroundNotification:(NSNotification*)notification_I;



//! @function didEnterForegroundNotification
//! @returns returns the SDK version string.
- (void)didEnterForegroundNotification:(NSNotification*)notification_I;
@end //@interface WacomManager



#pragma mark -
#pragma mark "Protocols"
#pragma mark -

//! Protocol WacomStylusEventCallback
//! @discussion this protocol provides the stylus Event callback which enables the registrant to be called
//! back in the event that the manger receives an event such as pressure or a button state change from
//! the stylus.
@protocol WacomStylusEventCallback <NSObject>
@required
- (void)stylusEvent:(WacomStylusEvent *)stylusEvent;
@end



//! Protocol WacomDiscoveryCallback
//! @discussion this protocol provides the registrant with notifications of when individual devices are
//! discovered or when bluetooth is turned off
@protocol WacomDiscoveryCallback <NSObject>

@required
//! @function deviceDiscovered
//! @abstract: notifies the registrant that a Wacom device has been discovered
- (void) deviceDiscovered:(WacomDevice *)device;



//! @function discoveryStatePoweredOff
//! @abstract notifies the registrant that bluetooth is powered off.
- (void) discoveryStatePoweredOff;


@optional
//! @function deviceConnected
//! @abstract notifies the registrant that a Wacom device is has been connected.
- (void) deviceConnected:(WacomDevice *)device;



//! @function deviceDisconnected
//! @abstract notifies the registrant that a Wacom device has been disconnecte.
- (void) deviceDisconnected:(WacomDevice *)device;

@end // @protocol WacomDiscoveryCallback

#endif //} WACOMDEVICEFRAMEWORK_H
