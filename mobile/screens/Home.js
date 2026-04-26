import React, { useState } from 'react';
import { View, Text, Image, StyleSheet, TextInput, ScrollView, TouchableOpacity } from 'react-native';

export default function Home() { 
  return (
    <ScrollView  style={styles.container}>
      <View style={styles.navContainer}>
        <View style={styles.navbarContainer}>
          <Text style={styles.navTittle}>system:</Text>
          <Text style={styles.navSubtittle}>Nutritrack ecosystem</Text>
        </View>
        <View style={styles.circle}></View>
        <Image source={require("../assets/search_icon.png")} style={styles.Image}/>
      </View>
      <View style={styles.userContainer}>
        <Text style={styles.userWelcome}>Welcome back</Text>
        <Text style={styles.userInfo}>1higgins</Text>
      </View>
      <View style={styles.cardContainer}>
        <TouchableOpacity style={styles.cardTelemetry}>
          <View style={styles.subCardTelemetry}>
            <View style={styles.subCardStatus}>
              <Text style={styles.statusTittle}>Status Telemetry:</Text>
              <Text style={styles.statusMain}>Stable</Text>
              <Text style={styles.statusUpdate}>Last update: 9:39</Text>
            </View>
            <Image source={require("../assets/hand_icon.png")} style={styles.Image2}/>
          </View>
        </TouchableOpacity>
        <View style={styles.gridContainer}>
          <TouchableOpacity style={styles.cardInfo1}></TouchableOpacity>

          <TouchableOpacity style={styles.cardInfo1}></TouchableOpacity>

          <TouchableOpacity style={styles.cardInfo1}></TouchableOpacity>

          <TouchableOpacity style={styles.cardInfo1}></TouchableOpacity>
        </View>
      </View>

    </ScrollView>
  );
}

const styles = StyleSheet.create({

  container:{
    flex: 1,
    backgroundColor:'#ebebeb',
    paddingHorizontal: 20,
    },
  navContainer:{
    alignItems:'center',
    width: '100%',
    marginTop: 50,
    height: 60,
    justifyContent: 'center',
    flexDirection: 'row',
    position: 'relative',
  },
  navbarContainer:{
    alignItems:'center',
  },
  navTittle:{ 
    color: '#706e6e',
  },
  navSubtittle  :{
    color: '#000000',
    fontSize: 17,
    fontWeight: 400
  },
  circle: {
  width: 40,
  height: 40,
  borderRadius: 100 / 2,
  backgroundColor: '#000000',
  position: 'absolute',
  right: 0,
  marginRight: 10
},
Image2:{
  width: 175,
  height: 175,
  position: 'absolute',
  top: -61,
  zIndex: 10,
},
Image:{
  width: 42,
  height: 42,
  position: 'absolute',
  left: 0,
  marginLeft: 10
},
userContainer:{
  marginTop: 25,
  paddingHorizontal: 10,
},
userWelcome: {
  fontSize: 23,
  fontWeight: 600,
  color: '#000000',
  textAlign: 'left',
},
userInfo: {
  fontSize: 50,
  fontWeight: 600,
  color: '#000',
  textAlign: 'left',
},
cardContainer:{
  marginTop: 30,
  width: '100%',
},
cardTelemetry: {
    height: 240,
    width: '100%',
    borderRadius: 30,
    backgroundColor: '#fff',
    justifyContent: 'flex-end',
    position: 'relative',
    overflow: 'visible',
    elevation: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.1,
    shadowRadius: 10,
  },
subCardTelemetry:{
  backgroundColor:'#000000',
  height: 110,
  width: '100%',
  borderRadius: 30,
},
cardInfo1:{
  marginTop: 15,
  height: 200,
  width: '48%',
  borderRadius: 30,
  backgroundColor: '#fff',
  shadowOffset: { width: 0, height: 10 },
  shadowColor: '#000',
  shadowOpacity: 0.1,
  shadowRadius: 8,
  marginBottom: 15
},
subCardStatus:{
  position:'absolute',
  top: 20,
  right: 20,
},
statusTittle: {
  fontSize: 22  ,
  color: '#ffffff',
},
statusMain: {
  fontSize: 22  ,
  color: '#ffffff',
},
statusUpdate: {
  fontSize: 15,
  color: '#b3b3b3',
  marginTop: 4,
},
gridContainer: {
  flexDirection: 'row',
  flexWrap: 'wrap',
  justifyContent: 'space-between',
  width: '100%',
  marginTop: 20,
},
})