#!/bin/bash

# Stop on the first sign of trouble
set -e

SCRIPT_COMMON_FILE=$(pwd)/../rak/rak/shell_script/rak_common.sh

if [ $UID != 0 ]; then
    echo_error "Operation not permitted. Forgot sudo?"
    exit 1
fi

source $SCRIPT_COMMON_FILE

mkdir -p /usr/local/rak/lora

RAK_GW_MODEL=`do_get_gw_model`
LORA_SPI=`do_get_lora_spi`
INSTALL_LTE=`do_get_gw_install_lte`

mkdir /opt/lora-gateway -p


if [ "${RAK_GW_MODEL}" = "RAK2247" ]; then
	if [ "${LORA_SPI}" = "1" ]; then
		pushd rak2247_spi
		./install.sh
		LORA_DIR_TMP=rak2247_spi
	else
		pushd rak2247_usb
		./install.sh
		LORA_DIR_TMP=rak2247_usb
	fi
	popd
elif [ "${RAK_GW_MODEL}" = "RAK2287" ] || [ "${RAK_GW_MODEL}" = "RAK7248" ] ; then
	pushd rak2287
	if [ "${LORA_SPI}" = "1" ]; then
		if [ "${INSTALL_LTE}" = "1" ]; then
			cp global_conf_i2c global_conf -rf
		else
			cp global_conf_uart global_conf -rf
		fi
	else
		cp global_conf_usb global_conf -rf
	fi
	./install.sh
	LORA_DIR_TMP=rak2287
	popd
elif [ "${RAK_GW_MODEL}" = "RAK5146" ]; then
	pushd rak5146
	if [ "${LORA_SPI}" = "1" ]; then
		if [ "${INSTALL_LTE}" = "1" ]; then
			cp global_conf_i2c global_conf -rf
		else
			cp global_conf_uart global_conf -rf
		fi
	else
		cp global_conf_usb global_conf -rf
	fi
	./install.sh
	LORA_DIR_TMP=rak5146
	popd
elif [ "${RAK_GW_MODEL}" = "RAK7243" ] || [ "${RAK_GW_MODEL}" = "RAK7244" ]; then
	pushd rak7243
	if [ "${INSTALL_LTE}" = "1" ]; then
		cp global_conf_i2c global_conf -rf
	else
		cp global_conf_uart global_conf -rf
	fi
	./install.sh
	LORA_DIR_TMP=rak7243
	popd
else
	if [ "${RAK_GW_MODEL}" = "RAK2246" ]; then
		pushd rak2246
		./install.sh
		LORA_DIR_TMP=rak2246
	else
		pushd rak7243
		cp global_conf_uart global_conf -rf
		./install.sh
		LORA_DIR_TMP=rak7243
	fi
	popd
fi


if [ -d $LORA_DIR_TMP/lora_gateway ]; then
    cp $LORA_DIR_TMP/lora_gateway /opt/lora-gateway/ -rf
fi
cp $LORA_DIR_TMP/packet_forwarder /opt/lora-gateway/ -rf


cp ./update_gwid.sh /opt/lora-gateway/packet_forwarder/lora_pkt_fwd/update_gwid.sh
cp ./start.sh  /opt/lora-gateway/packet_forwarder/lora_pkt_fwd/start.sh
cp ./set_eui.sh  /opt/lora-gateway/packet_forwarder/lora_pkt_fwd/set_eui.sh
cp lora-gateway.service /lib/systemd/system/lora-gateway.service
cp /opt/lora-gateway/packet_forwarder/lora_pkt_fwd/global_conf/global_conf.eu_863_870.json \
	/opt/lora-gateway/packet_forwarder/lora_pkt_fwd/global_conf.json
	
rpi_model=`do_get_rpi_model`
if [ $rpi_model -eq 3 ] || [ $rpi_model -eq 4 ]; then
    sed -i "s/^.*server_address.*$/\t\"server_address\": \"127.0.0.1\",/" \
	/opt/lora-gateway/packet_forwarder/lora_pkt_fwd/global_conf.json
fi

systemctl enable lora-gateway.service
systemctl restart lora-gateway.service

