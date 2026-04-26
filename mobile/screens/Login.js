import React, { useState } from 'react';
import { View, Text, Image, StyleSheet, TextInput, ScrollView, TouchableOpacity } from 'react-native';

export default function Login({navigation}) { 
    const [role, setRole] = useState(null);
    const [form, setForm] = useState({
        email: '',
        password: '',
    });

  return (
    <View contentContainerStyle={styles.container}>
        <View style={styles.headerContainer}>
            <Image source={require("../assets/login_image.png")} style={styles.Image}/>
            <Text style={styles.tittle}>Welcome</Text>
            <Text style={styles.subtittle}>You just need sign in</Text>
        </View>

        <View style={styles.formContainer}>
            <View style={styles.loginCard}>
                <Text style={styles.cardTitle}>Login</Text>
                
                <View style={styles.inputLabel}>
                    <TextInput
                        style={styles.inputControl}
                        autoCapitalize='none'
                        value={form.email}
                        onChangeText={email => setForm({...form, email})}
                        placeholder='Operator ID'
                    />
                </View>

                <View style={styles.inputLabel}>
                    <TextInput
                        style={styles.inputControl}
                        secureTextEntry={true}
                        value={form.password}
                        onChangeText={password => setForm({...form, password})}
                        placeholder='Access Key'
                    />
                </View>

                <View style={styles.formIn}>
                    <TouchableOpacity onPress={() => {navigation.navigate('Home', { userRole: role });}}>
                        <View style={styles.buttonCard}>
                            <Text style={styles.buttonText}>Sign In</Text>
                        </View>
                    </TouchableOpacity>
                </View>
            </View>
        </View>
    </View>
  );
}

const styles = StyleSheet.create({
    container:{
        flexGrow: 1,
        backgroundColor:'#f5f5f5',
        paddingHorizontal: 20,
    },
    headerContainer:{
        alignItems:'center',
        marginTop: 50,
        marginBottom: 30
    },
    Image:{
        width: 250,
        height: 250,
        resizeMode: 'contain'
    },
    tittle:{
        fontSize: 32,
        fontWeight: 500,
        marginTop: 10,
        color: '#000'
    },
    subtittle:{
        fontSize: 16,
        color: '#797475',
    },
    formContainer: {
        flexDirection: 'row',
        justifyContent: 'center',
        width: '100%',
    },
    loginCard: {
        backgroundColor: '#ffffff',
        padding: 25,
        borderRadius: 30,
        width: '80%',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 10 },
        shadowOpacity: 0.05,
        shadowRadius: 10,
        elevation: 5,
    },
    cardTitle: {
        fontSize: 28,
        fontWeight: 'bold',
        marginBottom: 20,
    },
    inputLabel: {
        borderBottomWidth: 1,
        borderBottomColor: '#eee',
        marginBottom: 20,
    },
    inputControl:{
        fontSize: 18,
        paddingVertical: 10,
        color: '#333',
        textAlign: 'left',
    },
    buttonCard:{
        marginTop: 15,
        backgroundColor:'#242424',
        padding: 20,
        borderRadius: 20,
        alignItems:'center',
        justifyContent:'center'
    },
    buttonText:{
        color:'white',
        textAlign:'center',
        fontSize:15
    }
});