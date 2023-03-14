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
static nrf_saadc_value_t m_buffer_pool[2][SAMPLE_BUFFER_LEN]; 


// Create a handle which points to timer 1 instance
static const nrf_drv_timer_t m_timer = NRF_DRV_TIMER_INSTANCE(1);

// Create a PPI channel struct which will hold the alotted channel address
static nrf_ppi_channel_t m_ppi_channel;




// An empty handler for the timer because we cannot pass a null value to the timer init function
void timer_handler(nrf_timer_event_t event_type, void * p_context)
{}



// Create a function which will initialize all the PPI and timer related configurations
void timer_with_ppi_init(void)
{
   ret_code_t err_code; // a variable to hold the error code

// Initialize the PPI (make sure its initialized only once in your code)
   err_code = nrf_drv_ppi_init();
   APP_ERROR_CHECK(err_code); // check for errors

// Create a config struct which will hold the timer configurations.
   nrf_drv_timer_config_t timer_cfg = NRF_DRV_TIMER_DEFAULT_CONFIG; // configure the default settings
   timer_cfg.bit_width = NRF_TIMER_BIT_WIDTH_32; // change the timer's width to 32- bit to hold large values for ticks 

// Initialize the timer with timer handle, timer configurations, and timer handler
   err_code = nrf_drv_timer_init(&m_timer, &timer_cfg, timer_handler);
   APP_ERROR_CHECK(err_code); // check for errors


// A variable to hold the number of ticks which are calculated in this function below
    uint32_t ticks = nrf_drv_timer_ms_to_ticks(&m_timer, 50);

// Initialize the channel 0 along with configurations and pass the Tick value for the interrupt event 
    nrf_drv_timer_extended_compare(&m_timer, NRF_TIMER_CC_CHANNEL0, ticks, NRF_TIMER_SHORT_COMPARE0_CLEAR_MASK, false);
 
// Enable the timer - it starts ticking as soon as this function is called 
	nrf_drv_timer_enable(&m_timer);



// Save the address of compare event so that it can be connected to ppi module
    uint32_t timer_compare_event_addr = nrf_drv_timer_compare_event_address_get(&m_timer, NRF_TIMER_CC_CHANNEL0);
	
// Save the task address to a variable so that it can be connected to ppi module for automatic triggering
    uint32_t saadc_sample_task_addr = nrf_drv_saadc_sample_task_get();

// Allocate the ppi channel by passing it the struct created at the start
    err_code = nrf_drv_ppi_channel_alloc(&m_ppi_channel);
    APP_ERROR_CHECK(err_code); // check for errors
	
	
// attach the addresses to the allocated ppi channel so that its ready to trigger tasks on events
    err_code = nrf_drv_ppi_channel_assign(m_ppi_channel, timer_compare_event_addr, saadc_sample_task_addr);
    APP_ERROR_CHECK(err_code); // check for errors


}




// Handle the events once the samples are received in the buffer
void saadc_callback_handler(nrf_drv_saadc_evt_t const * p_event)
{
    float val; // a float variable to hold the arithmatic calculations data.

    if(p_event -> type == NRFX_SAADC_EVT_DONE) // check if the sampling is done and we are ready to take these samples for processing
    {
      ret_code_t err_code; // a variable to hold errors code

// A function to take the samples (which are in the buffer in the form of 2's complement), and convert them to 16-bit interger values
      err_code = nrfx_saadc_buffer_convert(p_event->data.done.p_buffer, SAMPLE_BUFFER_LEN);
      APP_ERROR_CHECK(err_code); // check for errors

// a simple variable for loop
      int i;

// simple log message to show some event occured
      NRF_LOG_INFO("ADC Event Occurred!!");

// For loop is used to read and process each variable in the buffer, if the buffer size is 1, we don't need for loop
      for(i = 0; i<SAMPLE_BUFFER_LEN; i++)
      {
        NRF_LOG_INFO("Sample Value Read: %d", p_event->data.done.p_buffer[i]); // read the variable and print it

// Perform some calculations to convert this value back to the voltage
        val = p_event->data.done.p_buffer[i] * 3.6 / 4096;
		
		// use NRF log special marker to output the floating point values.
        NRF_LOG_INFO("Voltage Read: " NRF_LOG_FLOAT_MARKER "\r\n", NRF_LOG_FLOAT(val));

      
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

// Initialize the adc module Null is for configurations, they can be configured via CMSIS Configuration wizard so we don't need to pass anything here
  err_code = nrf_drv_saadc_init(NULL, saadc_callback_handler);
  APP_ERROR_CHECK(err_code);

// allocate the channel along with the configurations
  err_code = nrfx_saadc_channel_init(0, &channel_config);
  APP_ERROR_CHECK(err_code);

// allocate first buffer where the values will be stored once sampled
  err_code = nrfx_saadc_buffer_convert(m_buffer_pool[0], SAMPLE_BUFFER_LEN);
  APP_ERROR_CHECK(err_code);

// allocate second buffer where the values will be stored if overwritten on first before reading
  err_code = nrfx_saadc_buffer_convert(m_buffer_pool[1], SAMPLE_BUFFER_LEN);
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
// call the timers initialization function here
    timer_with_ppi_init();

// Enable the PPI channel to start receiving and triggering events
    ret_code_t err_code = nrf_drv_ppi_channel_enable(m_ppi_channel);
    APP_ERROR_CHECK(err_code);


// Disp[lay a message 
    NRF_LOG_INFO("Application started!!");
 

// Infinite loop do anything here. 
    while (1)
    {
       
    }
}


/** @} */
