/**
 * Copyright (c) 2014 - 2021, Nordic Semiconductor ASA
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form, except as embedded into a Nordic
 *    Semiconductor ASA integrated circuit in a product or a software update for
 *    such product, must reproduce the above copyright notice, this list of
 *    conditions and the following disclaimer in the documentation and/or other
 *    materials provided with the distribution.
 *
 * 3. Neither the name of Nordic Semiconductor ASA nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * 4. This software, with or without modification, must only be used with a
 *    Nordic Semiconductor ASA integrated circuit.
 *
 * 5. Any software provided in binary form under this license must not be reverse
 *    engineered, decompiled, modified and/or disassembled.
 *
 * THIS SOFTWARE IS PROVIDED BY NORDIC SEMICONDUCTOR ASA "AS IS" AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY, NONINFRINGEMENT, AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL NORDIC SEMICONDUCTOR ASA OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

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

nrf_saadc_value_t adc_val;

void saadc_callback_handler(nrf_drv_saadc_evt_t const * p_event) // blocking-mode
{
  // Empty handler function
}

void saadc_init(void)
{
  ret_code_t err_code; // uint32_t

  nrf_saadc_channel_config_t channel_config = NRFX_SAADC_DEFAULT_CHANNEL_CONFIG_SE(NRF_SAADC_INPUT_AIN2); // AIN2 Pin Reading, resolution = default(10bits)

  // Initialize the saadc
  err_code = nrf_drv_saadc_init(NULL, saadc_callback_handler);
  APP_ERROR_CHECK(err_code);

  // Initialize the Channel which will be connected to that specific pin
  err_code = nrfx_saadc_channel_init(0, &channel_config); // Pin=0
  APP_ERROR_CHECK(err_code);
  

  }

void log_init(void)
{
APP_ERROR_CHECK(NRF_LOG_INIT(NULL));

NRF_LOG_DEFAULT_BACKENDS_INIT();
}

void led_advertising(void)
{
  bsp_board_led_on(BSP_BOARD_LED_1);
  nrf_delay_ms(500);
  bsp_board_led_off(BSP_BOARD_LED_1);
}
/**
 * @brief Function for main application entry.
 */
int main(void)
{
  /* Configure board. */
  bsp_board_init(BSP_INIT_LEDS);

  log_init();

  saadc_init();

//  nrf_saadc_value_t adc_val;

  NRF_LOG_INFO("Application Started!");
    
    while (1)
    {

      nrfx_saadc_sample_convert(0,&adc_val); // Channel = 0
      
      NRF_LOG_INFO("Sample value Read: %d", adc_val);

      led_advertising();

      NRF_LOG_INFO("Volts: " NRF_LOG_FLOAT_MARKER "\r\n", NRF_LOG_FLOAT(adc_val * 3.6 / 1024)); // 1024 = 10 bits resolution
      
      nrf_delay_ms(500);

    }
}


/** @} */
