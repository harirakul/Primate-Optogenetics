#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "nrf.h"
#include "nrf_drv_saadc.h"
#include "nrf_drv_ppi.h"
#include "nrf_drv_timer.h"
#include "boards.h"
#include "app_error.h"
#include "nrf_delay.h"
#include "app_util_platform.h"
#include "nrf_pwr_mgmt.h"

#include "nrf_log.h"
#include "nrf_log_ctrl.h"
#include "nrf_log_default_backends.h"

/*
8 bit  = approx 0.01289     =  12.89  millivolts
10 bit = approx 0.003226    =  3.226  millivolts
12 bit = approx 0.00080566  =  0.80566 Millivolts = 805.66 Micro volts  4096
14 bit = approx 0.00020141  =  0.20141 Millivolts = 201.41 Micro Volts

*/

// Samples are needed to be stored in a buffer, we define the length here
#define SAMPLE_BUFFER_LEN 5 

// Save the samples in double buffer which is  a two dimentional array
//static nrf_saadc_value_t m_buffer_pool[2][SAMPLE_BUFFER_LEN]; 
static nrf_saadc_value_t adc_value_1[2][SAMPLE_BUFFER_LEN];
static nrf_saadc_value_t adc_value_2[2][SAMPLE_BUFFER_LEN];



// Handle the events once the samples are received in the buffer
void saadc_callback_handler(nrf_drv_saadc_evt_t const * p_event)
{
    float adc_val_1, adc_val_2; // a float variable to hold the arithmatic calculations data.

    if(p_event -> type == NRFX_SAADC_EVT_DONE) // check if the sampling is done and we are ready to take these samples for processing
    {
      ret_code_t err_code; // a variable to hold errors code

// A function to take the samples (which are in the buffer in the form of 2's complement), and convert them to 16-bit interger values
      err_code = nrfx_saadc_buffer_convert(adc_value_1[0], SAMPLE_BUFFER_LEN);
      err_code = nrfx_saadc_buffer_convert(adc_value_2[0], SAMPLE_BUFFER_LEN);
      APP_ERROR_CHECK(err_code); // check for errors

// a simple variable for loop
      int i;

// simple log message to show some event occured
      NRF_LOG_INFO("ADC Event Occurred!!");

// For loop is used to read and process each variable in the buffer, if the buffer size is 1, we don't need for loop
      for(i = 0; i<SAMPLE_BUFFER_LEN; i++){
        NRF_LOG_INFO("Sample Value Read: %d", adc_value_1[i]); // read the variable and print it

// Perform some calculations to convert this value back to the voltage
        adc_val_1 = adc_value_1[0][i] * 3.6 / 4096;

        		// use NRF log special marker to output the floating point values.
        NRF_LOG_INFO("Voltage Read: " NRF_LOG_FLOAT_MARKER "\r\n", NRF_LOG_FLOAT(adc_val_1));
       } 

        for(i = 0; i<SAMPLE_BUFFER_LEN; i++){
          NRF_LOG_INFO("Sample Value Read: %d", adc_value_2[i]); // read the variable and print it

          adc_val_2 = adc_value_2[0][i] * 3.6 / 4096;
        	
                  // use NRF log special marker to output the floating point values.
          NRF_LOG_INFO("Voltage Read: " NRF_LOG_FLOAT_MARKER "\r\n", NRF_LOG_FLOAT(adc_val_2));
       }
      
    }
}



// Create a function to initialize the saadc 
void saadc_init(void)
{
  ret_code_t err_code; // variable to store the error code

// Create a struct to hold the default configurations which will be used to initialize the adc module.
// make sure to use the right pins
  nrf_saadc_channel_config_t channel_config = NRFX_SAADC_DEFAULT_CHANNEL_CONFIG_SE(NRF_SAADC_INPUT_AIN0);
  nrf_saadc_channel_config_t channel_1_config = NRFX_SAADC_DEFAULT_CHANNEL_CONFIG_SE(NRF_SAADC_INPUT_AIN2);
// Initialize the adc module Null is for configurations, they can be configured via CMSIS Configuration wizard so we don't need to pass anything here
  err_code = nrf_drv_saadc_init(NULL, saadc_callback_handler);
  APP_ERROR_CHECK(err_code);

// allocate the channel along with the configurations
  err_code = nrfx_saadc_channel_init(0, &channel_config);
  APP_ERROR_CHECK(err_code);

  err_code = nrfx_saadc_channel_init(1, &channel_1_config);
  APP_ERROR_CHECK(err_code);

// allocate first buffer where the values will be stored once sampled
  err_code = nrfx_saadc_buffer_convert(adc_value_1[0], SAMPLE_BUFFER_LEN);
  APP_ERROR_CHECK(err_code);

// allocate second buffer where the values will be stored if overwritten on first before reading
  err_code = nrfx_saadc_buffer_convert(adc_value_1[1], SAMPLE_BUFFER_LEN);
  APP_ERROR_CHECK(err_code);

// allocate first buffer where the values will be stored once sampled
  err_code = nrfx_saadc_buffer_convert(adc_value_2[0], SAMPLE_BUFFER_LEN);
  APP_ERROR_CHECK(err_code);

// allocate second buffer where the values will be stored if overwritten on first before reading
  err_code = nrfx_saadc_buffer_convert(adc_value_2[1], SAMPLE_BUFFER_LEN);
  APP_ERROR_CHECK(err_code);

}







/**
 * @brief Function for main application entry.
 */
int main(void)
{
	
	// Initialize the log
    APP_ERROR_CHECK(NRF_LOG_INIT(NULL));
    NRF_LOG_DEFAULT_BACKENDS_INIT();

// call the saadc function here
    saadc_init();


// Disp[lay a message 
    NRF_LOG_INFO("Application started!!");
 

// Infinite loop do anything here. 
    while (1)
    {
		
	   nrfx_saadc_sample(); // Call this function manually to trigger sampling 

       nrf_delay_ms(1000); // wait for 1 second
       
    }
}


/** @} */



/*

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "nrf.h"
#include "nrf_drv_saadc.h"
#include "nrf_drv_ppi.h"
#include "nrf_drv_timer.h"
#include "boards.h"
#include "app_uart.h"
#include "app_error.h"
#include "nrf_delay.h"
#include "app_util_platform.h"


#define UART_TX_BUF_SIZE 256 
#define UART_RX_BUF_SIZE 1   

#ifndef NRF_APP_PRIORITY_HIGH
#define NRF_APP_PRIORITY_HIGH 1
#endif

#define SAMPLES_IN_BUFFER 2
volatile uint8_t state = 1;

static uint32_t                m_adc_evt_counter;

void uart_events_handler(app_uart_evt_t * p_event)
{
}


void uart_config(void)
{
    uint32_t                     err_code;
    const app_uart_comm_params_t comm_params =
    {
        RX_PIN_NUMBER,
        TX_PIN_NUMBER,
        RTS_PIN_NUMBER,
        CTS_PIN_NUMBER,
        APP_UART_FLOW_CONTROL_DISABLED,
        false,
        UART_BAUDRATE_BAUDRATE_Baud38400
    };

    APP_UART_FIFO_INIT(&comm_params,
                       UART_RX_BUF_SIZE,
                       UART_TX_BUF_SIZE,
                       uart_events_handler,
                       APP_IRQ_PRIORITY_LOW,
                       err_code);

    APP_ERROR_CHECK(err_code);
}

void saadc_callback(nrf_drv_saadc_evt_t const * p_event)
{

}

void saadc_init(void)
{
    ret_code_t err_code;
	
    nrf_saadc_channel_config_t channel_0_config =
    NRF_DRV_SAADC_DEFAULT_CHANNEL_CONFIG_SE(NRF_SAADC_INPUT_AIN0);
		nrf_saadc_channel_config_t channel_1_config =
		NRF_DRV_SAADC_DEFAULT_CHANNEL_CONFIG_SE(NRF_SAADC_INPUT_AIN2);
	
    err_code = nrf_drv_saadc_init(NULL, saadc_callback);
    APP_ERROR_CHECK(err_code);

    err_code = nrf_drv_saadc_channel_init(0, &channel_0_config);
    APP_ERROR_CHECK(err_code);
	  err_code = nrf_drv_saadc_channel_init(1, &channel_1_config);
    APP_ERROR_CHECK(err_code);
}


int main(void)
{
		ret_code_t err_code;
		static nrf_saadc_value_t adc_value_0;
		static nrf_saadc_value_t adc_value_1;
	
    uart_config(); 

    printf("\n\rSAADC HAL simple example.\r\n");            //print initial message on UART
    saadc_init();                                           //Initialize SAADC and configure two SAADC channels

    while(1)
    {
				//Sample SAADC on two channels
				err_code = nrf_drv_saadc_sample_convert(0, &adc_value_0);
				APP_ERROR_CHECK(err_code);
				err_code = nrf_drv_saadc_sample_convert(1, &adc_value_1);
				APP_ERROR_CHECK(err_code);
			
				//Print the result on UART
				printf("ADC sample number: %d\r\n",(int)m_adc_evt_counter);
				printf("Sample channel 0: %d\r\n", adc_value_0);
				printf("Sample channel 1: %d\r\n", adc_value_1);
        m_adc_evt_counter++;
			
				nrf_delay_us(1000000);
    }
}

*/