//
//  AudioDeviceManager.m
//  FormantPlotter
//
//  Created by Muhammad Akmal Butt on 1/20/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "AudioDeviceManager.h"

@implementation AudioDeviceManager

AudioComponentInstance audioUnit;
AudioStreamBasicDescription audioFormat;
AudioBufferList* bufferList;
BOOL startedCallback;
BOOL noInterrupt;

//called when there is a new buffer of 1024 input samples available. 
static OSStatus recordingCallback(void* inRefCon,AudioUnitRenderActionFlags* ioActionFlags,const AudioTimeStamp* inTimeStamp,UInt32 inBusNumber,UInt32 inNumberFrames,AudioBufferList* ioData)
{
    int j;
    unsigned long bufferEnergy;
    
    // Create a local copy inside static function so that data could be accessed
    AudioDeviceManager *manager = (__bridge AudioDeviceManager *)inRefCon;
    
	if(startedCallback && noInterrupt) {
        OSStatus result = AudioUnitRender(audioUnit,ioActionFlags,inTimeStamp,inBusNumber,inNumberFrames,bufferList);
		switch(result)
		{
			case kAudioUnitErr_InvalidProperty: 
            {
                NSLog(@"AudioUnitRender Failed: Invalid Property"); 
                break;
            }
			case -50: 
            {
                NSLog(@"AudioUnitRender Failed: Invalid Parameter(s)"); 
                break;
            }
		}
        
        // If everything is OK above and we did not exit, we have a valid buffer. Compute its energy.
        short signed int *source= (short signed int *)bufferList->mBuffers[0].mData; 
        bufferEnergy = 0;
        for (j = 0; j < inNumberFrames; j++) {
            bufferEnergy = bufferEnergy + source[j]*source[j]; 
        }
	}
    
    // If energy is above the threshold, copy 1024 samples to the long buffer.
    
    if (manager->startCapturing == FALSE && manager->capturingComplete == FALSE && bufferEnergy > manager->energyThreshold ) {
        short signed int *source= (short signed int *)bufferList->mBuffers[0].mData; 
        for (j = 0; j < inNumberFrames; j++) {
            manager->longBuffer[j] = source[j];
        }
        manager->bufferSegCount = 1;
        manager->startCapturing = TRUE;
    }
    
    // If energy in 1024 sample buffer is at least 20% of the starting threshold, continue accumulating sound buffer.
    if (manager->startCapturing == TRUE && manager->capturingComplete == FALSE)
    {
        if (bufferEnergy > (manager->energyThreshold/5) ) 
        {
            short signed int *source= (short signed int *)bufferList->mBuffers[0].mData; 
            for (j = 0; j < inNumberFrames; j++) {
                manager->longBuffer[j + manager->bufferSegCount * 1024] = source[j];
            }
            manager->bufferSegCount = manager->bufferSegCount + 1;
        }
        else       // energy in 1024 sample buffer is below 20% of starting threshold. Stop capturing.
        {
            NSLog(@"\n");
            manager->startCapturing = TRUE;
            manager->capturingComplete = TRUE;
        }
    }
    return noErr;
}

void callbackInterruptionListener(void* inClientData, UInt32 inInterruption)
{
	NSLog(@"audio interruption %lu", inInterruption);
	AudioDeviceManager *manager = (__bridge AudioDeviceManager *)inClientData;
	if(inInterruption) {
		noInterrupt = NO;
		[manager closeDownAudioDevice];
		startedCallback	= NO;
	}
	else {
		if (noInterrupt==NO) {
			[manager setUpAudioDevice]; //restart audio session
			noInterrupt = YES;
		}
	}
}

-(void)setUpData {
	bufferList = (AudioBufferList*) malloc(sizeof(AudioBufferList));
	bufferList->mNumberBuffers = 1; //mono input
	for(UInt32 i=0;i<bufferList->mNumberBuffers;i++)
        
	{
		bufferList->mBuffers[i].mNumberChannels = 1;
		bufferList->mBuffers[i].mDataByteSize = (1024*2) * 2; 
		bufferList->mBuffers[i].mData = malloc(bufferList->mBuffers[i].mDataByteSize);
	}
    
    longBuffer = (short int *)(malloc(1024000 * sizeof(short int)));
}

-(void)freeData {
	for(UInt32 i=0;i<bufferList->mNumberBuffers;i++) {
		free(bufferList->mBuffers[i].mData);
	}	
	free(bufferList);
    
    free(longBuffer);
}

//lots of setup required
-(OSStatus)setUpAudioDevice {
	OSStatus status;
	
	startedCallback = NO;
	noInterrupt = YES; 
	
	// Describe audio component
	AudioComponentDescription desc;
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_RemoteIO;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
	//setup AudioSession for safety (interruption handling):
	AudioSessionInitialize(NULL,NULL,callbackInterruptionListener,(__bridge void *)(self));
	AudioSessionSetActive(true);
	
	UInt32 sizeofdata;
    
	NSLog(@"Audio session details\n");
	
	UInt32 audioavailableflag; 
	
	//can check whether input plugged in
	sizeofdata= sizeof(audioavailableflag); 
	status= AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable,&sizeofdata,&audioavailableflag);
	
	//no input capability
	if(audioavailableflag==0) {
		
		return 1; 
	}
		
	UInt32 numchannels; 
	sizeofdata= sizeof(numchannels); 
	status= AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareInputNumberChannels,&sizeofdata,&numchannels);
		
	sizeofdata= sizeof(numchannels); 
	status= AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareOutputNumberChannels,&sizeofdata,&numchannels);
	
	Float64 samplerate; 
	samplerate = 44100.0; //44100.0; //supports and changes to 22050.0 or 48000.0 too!; //44100.0; 
	status= AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareSampleRate,sizeof(samplerate),&samplerate);
	
	sizeofdata= sizeof(samplerate); 
	status= AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate,&sizeofdata,&samplerate);
    
	NSLog(@"Device sample rate %5.0f \n",samplerate);
	
	//set preferred hardward buffer size of 1024; part of assumptions in callbacks
	
	Float32 iobuffersize = 1024.0/44100.0; 
	status= AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration,sizeof(iobuffersize),&iobuffersize);
	
	
	sizeofdata= sizeof(iobuffersize); 
	status= AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareIOBufferDuration,&sizeofdata,&iobuffersize);
	
	NSLog(@"Hardware buffer size %4.1f mSec.\n",iobuffersize*1000);
	
	//there are other possibilities
	UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord; //both input and output
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,sizeof(audioCategory),&audioCategory);
	
	// Get component
	AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
	
	// Get audio units
	status = AudioComponentInstanceNew(inputComponent, &audioUnit);
	
	if(status!= noErr) {
		
		NSLog(@"failure at AudioComponentInstanceNew\n"); 
		
		return status; 
	}; 
	
	UInt32 flag = 1;
	//UInt32 kOutputBus = 0;
	UInt32 kInputBus = 1;
	
	// Enable IO for recording
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioOutputUnitProperty_EnableIO, 
								  kAudioUnitScope_Input, 
								  kInputBus,
								  &flag, 
								  sizeof(flag));
	
	if(status!= noErr) {
		NSLog(@"failure at AudioUnitSetProperty 1\n");
		return status; 
	};
    
    //will be used by code below for defining bufferList, critical that this is set-up second
	// Describe format; not stereo for audio input! 
	audioFormat.mSampleRate			= 44100.00;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
	audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mChannelsPerFrame	= 1;
	audioFormat.mBitsPerChannel		= 16;
	audioFormat.mBytesPerPacket		= 2;
	audioFormat.mBytesPerFrame		= 2;
	
	
	//for input recording
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_StreamFormat, 
								  kAudioUnitScope_Output, 
								  kInputBus, 
								  &audioFormat, 
								  sizeof(audioFormat));
	
	
	if(status!= noErr) {
		
		NSLog(@"failure at AudioUnitSetProperty 4\n"); 
		
		return status; 
	}; 
	
	// Set input callback
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = recordingCallback;
	callbackStruct.inputProcRefCon = (__bridge void *)(self);
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioOutputUnitProperty_SetInputCallback, 
								  kAudioUnitScope_Global, 
								  kInputBus, 
								  &callbackStruct, 
								  sizeof(callbackStruct));
	
	if(status!= noErr) {
		NSLog(@"failure at AudioUnitSetProperty 5\n");
		return status; 
	}; 
    	
	UInt32 allocFlag = 1;
	status= AudioUnitSetProperty(audioUnit,kAudioUnitProperty_ShouldAllocateBuffer,kAudioUnitScope_Input,1,&allocFlag,sizeof(allocFlag)); // == noErr)
	
	if(status!= noErr) {
		NSLog(@"failure at AudioUnitSetProperty 7\n");
		return status; 
	}; 
	
	status = AudioUnitInitialize(audioUnit);
	
	if(status == noErr)
	{
        
	}
	else {
		
		NSLog(@"failure at AudioUnitSetProperty 8\n"); 
		
		return status; 
	}	
	
	status = AudioOutputUnitStart(audioUnit);
	
	if (status == noErr) {
		
		audioproblems = 0; 
        
		startedCallback = YES;
        
	} else
	{
		
		UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:@"Problem with audio setup" message:@"Are you on an ipod touch without headphone microphone? Concat requires audio input, please make sure you have a microphone. Either set this up or hit Home button to exit" delegate:self cancelButtonTitle:@"Press me then plugin in microphone" otherButtonTitles:nil];
		[anAlert show];
	}
	return status; 
}

-(void)closeDownAudioDevice{
	OSStatus status = AudioOutputUnitStop(audioUnit);
	if(startedCallback) {
        startedCallback	= NO;
	}
	AudioUnitUninitialize(audioUnit);
	AudioSessionSetActive(false);
}

@end
